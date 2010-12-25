class PmElementsController < ApplicationController
 
  live_tree :element, :model => :pm_element
  
  # GET /pm_elements
  # GET /pm_elements.xml
  def index
    @pm_elements = PmElement.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pm_elements }
    end
  end
  	
  # GET /pm_elements/1
  # GET /pm_elements/1.xml
  def show
    @pm_element = PmElement.find(params[:id])  
    @pm_model = @pm_element.pm_model
    @pm_lib = @pm_model.pm_lib
    @pm_folder = @pm_model.pm_folder
    @element_root = @pm_model.element_root
    
    cookies[:tree_view_mode] ||= "en"
    if mode = params[:tree_view_mode]
    	cookies[:tree_view_mode] = mode
  	end
  	
    if request.xhr?
      render :partial => "show"
    else
    end
  end


  # GET /pm_elements/new
  # GET /pm_elements/new.xml
  def new
    @pm_element = PmElement.new(params[:pm_element])
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pm_element }
    end
  end

  # GET /pm_elements/1/edit
  def edit
    @pm_element = PmElement.find(params[:id])
  end
  
  def move
    @pm_element = PmElement.find(params[:id])
  	@pm_model = @pm_element.pm_model
  	if request.post?
  		move_to = PmElement.find(params[:move_to])    
  		begin                                
    		@pm_element.move_to!(move_to)                                           
 		    redirect_to move_to
  		rescue ActiveRecord::RecordInvalid => e 
  		  flash[:error] = e.record.errors.full_messages
  		  redirect_to @pm_element
  		end
  		                   
  	else
  		render :layout=>false
		end
  end

  # POST /pm_elements
  # POST /pm_elements.xml
  def create
    @pm_element = PmElement.new(params[:pm_element])             
    @pm_element.properties = OpenStruct.new params[:properties]
    if @pm_element.save
	 	  flash[:notice] = "#{@pm_element.name}保存成功！<br>#{@pm_element.track_change_warning}"
      render(:update){|page|
        if params[:commit]=~/父级/
          page.redirect_to( pm_folder_path(@pm_element.parent))
        else
          page.redirect_to(@pm_element) 
        end
      }        
    else
    	replace_with_facebox('new_pm_element', :action=>'new')  
    end
  end
  

  # PUT /pm_elements/1
  # PUT /pm_elements/1.xml
  def update
    @pm_element = PmElement.find(params[:id])   
    @pm_element.properties = OpenStruct.new params[:properties]
    render(:update){|page|         
	    if @pm_element.update_attributes(params[:pm_element])
	      flash[:notice] = "保存成功！<br>#{@pm_element.track_change_warning}"
	      if params[:from] == "index"
	      	page.redirect_to :back
      	else
      		page.redirect_to(@pm_element)
    		end	      
	    else
	      page.replace "pm_element_form", :partial => "show" 
	    end                 
    }
  end

  # DELETE /pm_elements/1
  # DELETE /pm_elements/1.xml
  def destroy
    @pm_element = PmElement.find(params[:id])
    @pm_element.destroy
    redirect_to pm_element_path(@pm_element.parent)
    
  end
  
  private
  
  def tam_layout
    if super == "application"
      "pm"
    else
      super
    end
  end
end
