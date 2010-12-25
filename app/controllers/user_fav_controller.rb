class UserFavController < ApplicationController
  def index
  end
  
  def update
  	@user_fav = UserFav.find(params[:id])
  	
  	if params[:go] == "withdraw"
  		@user_fav.delete
		else
			@user_fav.user = User.current
			@user_fav.save!
		end
		redirect_to :back
  end
  
  def show
  	@user_fav = UserFav.find(params[:id])
  end
  
  def new
    @favable = params[:clazz].constantize.find(params[:object_id])
    return if request.get?
    fav =	UserFav.find_or_init_by(User.current, @favable)
    r = if params[:go] == "del"
    	del_fav(fav)
  	else
  		save_fav(fav)
		end
		render :json=>r
  end
  
  private
  
  def save_fav(fav)
  	ok = false
  	text = ""
  	if fav.new_record?      	
    	if fav.save
    		ok = true
    		text = "收藏成功！"
  		else
  			text = "保存失败！"
			end
  	else
  			text = "请不要重复收藏！"
		end
		
		{:ok=>ok, :text=>text, :replace=>params[:unjoin_text]||"取消收藏", :repace_go=>"del"}
  end
  
  
  def del_fav(fav)
  	ok = false
  	text = ""
  	if !fav.new_record?      	
    	if fav.delete
  			text = "取消成功！"
  			ok = true
  		else
  			text = "取消失败！"
			end
  	else
    		text = "您还没有收藏！"
		end
		
		{:ok=>ok, :text=>text, :replace=>params[:join_text]||"收藏",:repace_go=>"save"}
  end
end
