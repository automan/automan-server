module UserFavHelper
	
  def link_to_fav(object, options={})
		opts = {:class=>"user-fav",:object_id=>object.id, :clazz=>object.class.to_s}.merge(options.slice(:join_text,:unjoin_text))
		 
    if UserFav.find_or_init_by(User.current, object).new_record?
      link_to_function(options[:join_text]||"收藏", "userFav(this)", opts.merge(:go=>"new"))
    else
      link_to_function(options[:unjoin_text]||"取消收藏","userFav(this)", opts.merge(:go=>"del"))
    end
  end
end
