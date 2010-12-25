# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout :tam_layout
  before_filter :set_current_user
  layout :automan_layout
  
protected
  
  def automan_layout
    if request.xhr?
      'ajax'
    else
      "application"
    end
  end

  def replace_with_facebox(id, replace_with_options)
 		replace_with = render_to_string(replace_with_options.reverse_merge(:layout=>false)) 
		render(:update){|page|page.replace(id, replace_with)}
	end
	
	def set_current_user  	
    User.current = User.find_by_login("admin")
  end
  
end
