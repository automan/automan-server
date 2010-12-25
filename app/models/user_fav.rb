class UserFav < ActiveRecord::Base
	belongs_to :user
  belongs_to :object, :polymorphic=>true
  
  def self.find_or_init_by(user, favable)
  	find_or_initialize_by_user_id_and_object_type_and_object_id(user.id, favable.class.to_s, favable.id)
  end
end
