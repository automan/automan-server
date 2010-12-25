class Ownerable < ActiveRecord::Base
  OWNER = 0
  CREATE_BY = 1
  UPDATE_BY = 2
  belongs_to :user
  belongs_to :object, :polymorphic=>true
  
  named_scope :by_user, lambda {|user|{:conditions => {:user_id     => user.id}}}
  named_scope :by_obj_type, lambda {|clazz|{:conditions => {:object_type     => clazz.to_s}}}
  named_scope :owned, :conditions => {:the_type => Ownerable::OWNER}
  named_scope :faved, :conditions => {:the_type => nil}
  named_scope :created, :conditions => {:the_type => Ownerable::CREATE_BY}

  # your can include this in your model
  # class YourModel
  #   include Ownerable::ARExt
  # end
  
  module ARExt
    def self.included(base)
      base.extend(ClassMethods)
      base.send :__ownerable
    end
    
    module ClassMethods
      def __ownerable
        after_create :ownerable_ext_after_create
        after_update :ownerable_ext_after_update
        has_many :ownerables, :as => :object, :dependent => :delete_all
      end
    end
    
    def owner
      ownerables_by(Ownerable::OWNER)
    end
    
    def owner_user
      ownerables_by(Ownerable::OWNER,"user")
    end
    
    def created_by(field=nil)
      ownerables_by(Ownerable::CREATE_BY, field)
    end
     
    def created_by_user
      ownerables_by(Ownerable::CREATE_BY,"user")
    end
    
    
    def updated_by(field=nil)
      ownerables_by(Ownerable::UPDATE_BY,field)
    end
    
    def updated_by_user
      ownerables_by(Ownerable::UPDATE_BY,"user")
    end
    
    def set_owner(user)
      assert user
      ownerable_ext_create_ownerable(user, Ownerable::OWNER)
    end
    
    
    def ownerable_ext_after_update
    	ownerable_ext_create_ownerable(User.current, Ownerable::UPDATE_BY)
    end
    
    def ownerable_ext_after_create            
      ownerable_ext_create_ownerable(User.current, Ownerable::CREATE_BY)
      ownerable_ext_create_ownerable(User.current, Ownerable::OWNER)
    end
    
    private 
    
    def ownerable_ext_create_ownerable(user, type)
      if found = ownerables_by(type)
        if found.user_id != user.id
          found.user_id = user.id
          found.save!
          return
        end
      else
        ownerables.create!(:object_type => self.class.to_s,  :the_type=>type, :user_id=>user.id)
      end
    end
    
    def ownerables_by(type,field=nil)
      result = ownerables.to_a.find{|e|e.the_type == type}
      if field
        result&&result.send(field)
      else
        result
      end
    end
  end
  
end