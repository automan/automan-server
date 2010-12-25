module OwnerableHelper
	
	def username(user)
    user ? user.nickname : "(无名)"
	end
	
	def ownerable_name(obj)
		["title","name","to_s"].each do |e|
			if obj.respond_to?(e)
				return obj.send(e)
			end
		end
	end
	
  def link_to_owner(object,options={})
    if owner_data = object.owner
      link_to_popup(username(owner_data.user), "/ownerable/show/#{owner_data.id}")
    else
      link_to_popup("认领owner", "/ownerable/new?clazz=#{object.class}&object_id=#{object.id}")
    end
  end
end
