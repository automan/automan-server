module Acts 
    module Customizable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_customizable(options = {})
          return if self.included_modules.include?(Acts::Customizable::InstanceMethods)
          cattr_accessor :customizable_options
          self.customizable_options = options
          before_validation_on_create { |customized| customized.custom_field_values }
          # Trigger validation only if custom values were changed
          # validate :custom_values, :on => :update, :if => Proc.new { |customized| customized.custom_field_values_changed? }
         
          class_eval <<-EOV
						include ::Acts::Customizable::InstanceMethods
					EOV
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        def custom_values
        	[]
        end
        
        def available_custom_fields
          # CustomField.find(:all, :conditions => "tbl_name = '#{self.class.table_name}'",
          #                        :order => 'position')
          []
        end
         
        def custom_field_values
          @custom_field_values ||= available_custom_fields.collect { |x| custom_values.detect { |v| v.custom_field == x } || custom_values.build(:custom_field => x, :value => nil) }
        end
        
        def custom_field_values_changed?
        	false
        end
        
        def custom_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_values.detect {|v| v.custom_field_id == field_id }
        end
        
        module ClassMethods
        end
      end
    end
  end
