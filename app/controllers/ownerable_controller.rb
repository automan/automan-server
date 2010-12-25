class OwnerableController < ApplicationController
  def index
  end
  
  def update
  	@ownerable = Ownerable.find(params[:id])
  	
  	if params[:go] == "withdraw"
  		@ownerable.delete
		else
			@ownerable.user = User.current
			@ownerable.save!
		end
		redirect_to :back
  end
  
  def show
  	@ownerable = Ownerable.find(params[:id])
  end
  
  def new
    @ownerable = params[:clazz].constantize.find(params[:object_id])
    if request.post?
      @ownerable.set_owner(params[:user_id].blank? ? User.current : User.find(params[:user_id]))
      flash[:notice] = "owner设置成功!"
      redirect_to :back
    end
  end
end
