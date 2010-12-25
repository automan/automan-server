class PmFoldersController < ApplicationController
  # GET /pm_folders
  # GET /pm_folders.xml                         
  #live_tree :folder, :model => :pm_folder
  before_filter :find_one, :only=>[:export, :show, :destroy, :edit, :export, :update, :delete_preview]
  # GET /pm_folders/1
  # GET /pm_folders/1.xml
  def show
    @pm_lib = params[:pm_lib_id] ?  PmLib.find(params[:pm_lib_id]) : @pm_folder.pm_lib
    @folder_root = @pm_lib.folder_root  
    if !@pm_lib.base?
      if @folder_root.children.empty?
    		return render :action => "show_empty"
      end
    	@pm_folder = @pm_lib.folder_root(@pm_folder)
  	end
    if request.xhr?
      list_view = render_to_string(:partial => @pm_lib.base? ?  "show" : "show_in_project")
      top_bar = render_to_string(:partial => "top_bar")
      render :json=>{:list_view=>list_view, :top_bar => top_bar}
      
    else
    	if @pm_folder.nil?
  	     redirect_to pm_lib_pm_folder_path(@pm_lib, @folder_root.id)
  		end
    end
  end
  
  def export
    return if request.get?
    ids = params[:page_ids]
    lib_id = params[:pm_lib_id]
    
    if ids.blank?
      return raise_error("please check as least one page!") 
    end
    
    if lib_id.blank?
      return raise_error("please choose a target Project Page Model Lib") 
    end
    @pm_lib = PmLib.find(lib_id)
    pages = ids.map{|e|PmModel.find(e)}
    duplicats = PmLink::Maker.new(pages, @pm_lib).make_init!
    
    flash[:notice] = %[成功导入到项目［#{@pm_lib.name}］, #{@template.link_to_pop_page("点击进入", "/pm_libs/#{@pm_lib.id}")}]
    if !duplicats.empty?
      flash[:error] = %[以下Page已经导入该项目中， 分别为：#{duplicats.map{|e|@template.link_to_pop_page(e.model_in_project.name, "/pm_libs/#{@pm_lib.id}/pm_models/#{e.model_in_project.id}")}}]
    end
    redirect_to :action => "show", :id=>@pm_folder
  end
  
  def download_help
  	@pm_folder = PmFolder.find(params[:id])
  end

  # GET /pm_folders/new
  # GET /pm_folders/new.xml
  def new
    @pm_folder = PmFolder.new
    @pm_folder.parent = PmFolder.find(params[:parent_id]) if params[:parent_id]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pm_folder }
    end
  end

  # GET /pm_folders/1/edit
  def edit
  end

  # POST /pm_folders
  # POST /pm_folders.xml
  def create
    @pm_folder = PmFolder.new(params[:pm_folder])  
    @pm_folder.pm_lib = @pm_folder.parent.pm_lib
		if params[:winmodel] == "yes"
			@pm_folder.folder_type = PmFolder::TYPE_WIN32
		end
    if @pm_folder.save
  	  flash[:notice] = "创建成功!<br>#{@pm_folder.track_change_warning}"
      render(:update){|page|page.redirect_to(@pm_folder)}
  	else
  		replace_with_facebox('new_pm_folder', :action=>'new')
  	end
  end

  # PUT /pm_folders/1
  # PUT /pm_folders/1.xml
  def update

    respond_to do |format|
      if @pm_folder.update_attributes(params[:pm_folder])
        flash[:notice] = "保存成功!<br>#{@pm_folder.track_change_warning}"
        format.html { redirect_to(@pm_folder) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pm_folder.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete_preview
    @pm_links = @pm_folder.all_pm_links
  end

  # DELETE /pm_folders/1
  # DELETE /pm_folders/1.xml
  def destroy
    return if request.get?
    @pm_folder.destroy

    respond_to do |format|
      format.html { redirect_to(pm_folder_url(@pm_folder.parent)) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  private
  
  def tam_layout
    if super == "application"
      "pm"
    else
      super
    end
  end
  
  def raise_error(msg)
    @error = msg
    return 
  end
  
  def find_one
    @pm_folder = PmFolder.find(params[:id])
  end
end
