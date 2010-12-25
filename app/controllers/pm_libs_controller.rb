class PmLibsController < ApplicationController
	before_filter :find_one, :only=>[:show, :edit, :update, :destroy, :fav_folder, :close]
	layout "home", :only=>"index"
  # GET /pm_libs
  # GET /pm_libs.xml
  def simple_list
    @pm_libs = PmLib.paginate(:page=>params[:page], :per_page=>10)
  end
  
  def close 
    return if request.get?
    @pm_lib.close!
    flash[:notice] = "关闭成功！"
    redirect_to pm_lib_path(@pm_lib)
  end
  
  def revision
  	params[:root_path] ||= "http://svn.test.taobao.net/repos/test-svnrepos/automan/code/share_modules/"
  	conf = Scm::Svn::Client::Config
  	#begin
  	revision = Scm::Svn::Client.new(params[:root_path]+params[:svn_path],:login=>conf["login"], :password=>conf["password"]).info.lastrev.identifier  	  	
  	respond_to do |format|
  		format.xml{
  		render :xml => {:revision => revision, :file_url => "http://automan.taobao.net:8001/redmine/projects/tam/repository/raw/share_modules/#{params[:svn_path]}"}.to_xml(:root=>"result")
			}
  	end
  	
  	#rescue Exception => e
  	#	render :text => 0
  	#end  	
  end
  
  def monkey_api
    @pm_lib = PmLib.find(params[:pm_lib_id]) if params[:pm_lib_id]
    @pm = PmModel.find(params[:pm_id]) if params[:pm_id]
    render :layout => false
  end

  # GET /pm_libs/1
  # GET /pm_libs/1.xml
  def show
    @folder_root = @pm_lib.folder_root        
    respond_to do |format|
      format.html {
        raise "@folder_root is nil" if @folder_root.nil?
        redirect_to pm_lib_pm_folder_path(@pm_lib, @folder_root.id)
      }
      format.xml{ 
        render :xml => @pm_lib.full_xml
      }
    end

  end
  
  def fav_folder
  	
  end

  # GET /pm_libs/new
  # GET /pm_libs/new.xml
  def new
    @pm_lib = PmLib.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pm_lib }
    end
  end

  # GET /pm_libs/1/edit
  def edit
    @pm_lib = PmLib.find(params[:id])
  end

  # POST /pm_libs
  # POST /pm_libs.xml
  def create
    @pm_lib = PmLib.new(params[:pm_lib])
    if @pm_lib.save
      flash[:notice] = '对象库创建成功'
      render(:update){|page|page.redirect_to(@pm_lib) }
    else 
    	replace_with_facebox('new_pm_lib', :action=>'new')
    end
  end

  # PUT /pm_libs/1
  # PUT /pm_libs/1.xml
  def update
    respond_to do |format|
      if @pm_lib.update_attributes(params[:pm_lib])
        flash[:notice] = 'PmLib was successfully updated.'
        format.html { redirect_to(@pm_lib) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pm_lib.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pm_libs/1
  # DELETE /pm_libs/1.xml
  def destroy
    @pm_lib.destroy

    respond_to do |format|
      format.html { redirect_to(pm_libs_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def bookmark
  	
  end
  
  
private
	def find_one
		@pm_lib = if params[:id].integer?
			PmLib.find(params[:id])
		else
			PmLib.find_by_name(params[:id])
		end
	end
end
