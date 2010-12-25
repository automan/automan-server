module Acts #:nodoc:
   module ActiveRecord
    module AutoIncrement #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # TODO descriptions here
      #
      #   class TodoItem < ActiveRecord::Base
      #     acts_as_autoincrement "number", :scope => :model_id
      #   end
      #
      module ClassMethods
        # Configuration options are:
        #
        # * +column+ - specifies the column name to auto-increment
        # * +scope+ - restricts what is to be considered a list. Given a symbol, it'll attach <tt>_id</tt> 
        def acts_as_autoincrement(*args)
          if args.empty? || !([Symbol, String].include?(args.first.class))
            raise ArgumentError, "the first argument should be a 'column name'"
          end
          
          options = args.extract_options!
          configuration = {:scope => "1 = 1", :column=> args.first}
          configuration.update(options)
          configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/
            
          if configuration[:scope].is_a?(Symbol)
            scope_condition_method = %(
              def scope_condition
                if #{configuration[:scope].to_s}.nil?
                  "#{configuration[:scope].to_s} IS NULL"
                else
                  "#{configuration[:scope].to_s} = \#{#{configuration[:scope].to_s}}"
                end
              end
            )
          else
            scope_condition_method = "def scope_condition() \"#{configuration[:scope]}\" end"
          end

          class_eval <<-EOV
            include Acts::ActiveRecord::AutoIncrement::InstanceMethods
 

            def auto_increment_column
              '#{configuration[:column]}'
            end

            #{scope_condition_method}

            before_create  :auto_increment_before_create
          EOV
        end
      end

      # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
      # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
      # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
      # the first in the list of all chapters.
      module InstanceMethods
        private
          def auto_increment_before_create

              record = self.class.find(:first, :conditions => scope_condition, :order => "#{auto_increment_column} DESC")
              self[auto_increment_column] = if record
                record[auto_increment_column].to_i + 1
              else
                1
              end
             
          end
      end 
    end
  end
end
