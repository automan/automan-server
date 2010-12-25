module Automan
  module UserExt
    def owns(type)
      ownerables.by_obj_type(type.to_s).map(&:object).uniq.compact
    end
    
    def favs(type)
      user_favs.scoped_by_object_type(type.to_s).map(&:object).uniq.compact
    end
    
    def fav_or_owns(type)
      owns(type)+favs(type)
    end
    
  end
end
