class PmModelsController < ApplicationController

  live_tree :pm_elements_tree, :model => :pm_element
  before_filter :find_one, :only=>[:diff, :history,:link_status, :edit_in_project, :merge_to_base]
  
  def preview
    # return if request.get?
    @pm_lib = PmLib.find(params[:pm_lib_id])

    if !(xml = params[:xml]).blank?
      begin
        render :text=>(render_to_string :partial =>  "shared/page_model", :locals => {:page_model=>@pm_lib.pm_models.build.import_xml(xml,false), :preview=>true})
      rescue Exception => e
        raise e
        error_trace = e.backtrace.unshift(e.message).join("\n")
        logger.error error_trace
        render :text => "<h2>Make sure you input the valid xml</h2><pre>#{error_trace}</pre>"
      end
      
    else
      render :text=>"<h2>Please Input xml first!</h2>"
    end
  end
  
  def merge_to_base
    if @pm_model.base?
      assert @pm_model.not_imported?
      @pm_model.merge_not_imported!
      flash[:notice] = "合并成功！"
      redirect_to pm_lib_pm_folder_path(@pm_model.pm_links.first.pm_lib, @pm_model.pm_folder)
    else
      @pm_lib = PmLib.find(params[:pm_lib_id])
      if request.get?
        @current_version = @pm_model.current_version.diff_title_prefix("项目中：")
        @bm_version = @pm_model.bm.current_version.diff_title_prefix("基线中：")
        @diff = @current_version.diff(@bm_version)
      else
        begin
          if params[:same]
            @pm_model.merge_without_change
          else
            @pm_model.merge_to_base(params[:merged])
          end
          flash[:notice] = "合并成功"
          redirect_to pm_lib_pm_folder_path(@pm_model.pm_lib, @pm_model.pm_folder)
        rescue Exception => e
          raise e
          logger.error( e.backtrace.unshift(e.message).join("\n") )
          flash[:error] = e.message
          redirect_to :action => "merge_to_base"
        end
      end
    end

  end
	
  # GET /pm_models
  # GET /pm_models.xml
  def index
    @pm_models = PmModel.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pm_models }
    end
  end
  
  def upload_pic
  	@pm_model = PmModel.find(params[:id])          
  	return if request.get?    
    @pm_model.image = params[:pm_model][:image]
    @pm_model.save!
    redirect_to :back
  end
  
  def import
    @pm_lib = PmLib.find(params[:pm_lib_id])
  	@pm_model = @pm_lib.pm_models.build(params[:pm_model])
  	return if request.get?
  	
  	begin
  		@pm_model.import_xml
  		flash[:notice] = "Page: #{@pm_model.title}保存成功！"
      render(:update){|page|page.redirect_to( pm_folder_path(@pm_model.pm_folder))}
  	rescue Exception => e
  		@error_message = e.message
  		@pm_model.destroy if !@pm_model.new_record?
  		raise e
  		replace_with_facebox('import_pm_model', :action=>'import')
  	end
  end

  # GET /pm_models/1
  # GET /pm_models/1.xml
  def show   
    @pm_model = PmModel.find(params[:id])                        
    @element_root = @pm_model.element_root
    raise AssertionError.new if @element_root.nil?
    respond_to do |format|
    	format.html{ redirect_to pm_model_pm_element_path(@pm_model, @element_root)}
    	format.json { render :json => @pm_model.to_json(:include => :pm_elements)}
    	format.xml { render :xml => @pm_model.full_xml }
    end
    
  end

  # GET /pm_models/new
  # GET /pm_models/new.xml
  def new
    @pm_model = PmModel.new(params[:pm_model])
    
    @pm_model.pm_lib = params[:pm_lib_id].blank? ? PmLib::BASE : PmLib.find(params[:pm_lib_id])
    if params[:folder_id] 
      @pm_model.pm_folder_id = params[:folder_id]
      if @pm_model.pm_folder.leaf?
        render :partial => "form", :layout=>false
      else
        render :text => "您不能在此目录下创建Page, 请选择其他目录!"
      end
      return
    else
      params[:pm_folder_id] && @pm_model.pm_folder_id = params[:pm_folder_id]
    end
    
    
    
    if !@pm_model.pm_lib.base?
      if @pm_model.pm_folder.root?
    	  return render :action => "select_folder"
    	else
    	  return render :action => "new_in_project"
  	  end
  	end
  end

  # GET /pm_models/1/edit
  def edit
    @pm_model = PmModel.find(params[:id])
  end

  # POST /pm_models
  # POST /pm_models.xml
  def create
    @pm_model = PmModel.new(params[:pm_model])
    @pm_lib = @pm_model.pm_lib
    assert @pm_lib
    
    params[:pm_lib_id]||=params[:pm_model][:pm_lib_id]
    saved = if @pm_model.pm_lib.base?
      @pm_model.save
    else
      @pm_model.create_in_project      
    end
    if saved
  	  flash[:notice] = "Page: #{@pm_model.name}保存成功！<br>#{@pm_model.track_change_warning}"
      render(:update){|page|page.redirect_to( pm_lib_pm_folder_path(@pm_lib, @pm_model.pm_folder))}
  	else
  		replace_with_facebox('new_pm_model', :action=>'new')
  	end
  end

  # PUT /pm_models/1
  # PUT /pm_models/1.xml
  def update
    @pm_model = PmModel.find(params[:id])
    @pm_element = @pm_model.element_root
    render(:update) do |page|    
      page_params = params[:pm_model]
      page_params[:name]&&(@pm_model.name = page_params[:name])
      @pm_model.title = page_params[:title]     
      @pm_model.url   = page_params[:url]     
      if @pm_model.save
      	flash[:notice] = "保存成功！<br>#{@pm_model.track_change_warning}"
      	page.redirect_to(@pm_element)
    	else                      
	      page.replace "pm_element_form", :partial => "pm_elements/show" 
  		end     
    end
  end
  
  def edit_in_project
    return if request.get?
    link = @pm_model.pm_links.find_by_project_id(params[:pm_lib_id])
    new_model = link.create_project_copy
    if new_model.errors.size == 0
      flash[:notice] = "您现在编辑的是一个副本！"
      redirect_to :action => "show", :id => new_model
    else
      flash[:error] = "operation failed!<br>#{new_model.errors.full_messages.join('<br>')}"
      redirect_to pm_lib_pm_folder_path(params[:pm_lib_id], @pm_model.pm_folder_id)
    end
    
  end
  
  def history
    @versions = @pm_model.versions.paginate(:page=>params[:page])
  end
  
  def diff
    load 'extensions/all.rb'
    @diff = @pm_model.diff(params[:to], params[:from])
  end

  # DELETE /pm_models/1
  # DELETE /pm_models/1.xml
  def destroy
    @pm_model = PmModel.find(params[:id])
    @pm_lib = @pm_model.not_imported?  ? @pm_model.pm_links.first.pm_lib  : PmLib::BASE 
    if (proj_id = params[:project])&&proj_id.to_i!=PmLib::BASE_ID
      @pm_lib = PmLib.find(proj_id)
      @pm_model = @pm_model.bm if !@pm_model.base?
      @pm_model.pm_links.find_by_project_id(proj_id).destroy
    else
      @pm_model.destroy
    end
    
    flash[:notice] = "删除成功！"

    respond_to do |format|
      format.html { redirect_to(pm_lib_pm_folder_path(@pm_lib, @pm_model.pm_folder)) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def find_one
    @pm_model = PmModel.find(params[:id])        
  end
  
end
