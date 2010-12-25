class PmVersionsController < ApplicationController
  before_filter :find_one, :only=>[]
	
  def index
  end
  
  def diff
    @pm_model = PmModel.find(params[:pm_model_id])
    @pm_version = @pm_model.versions.find_by_number(params[:number])
    
    @from_version = @pm_model.versions.find_by_number(params[:from])
    @diff_type = params[:type]||"sbs"
    
    @diff = @from_version.diff(@pm_version)
  end
  
  
  def show
    @pm_model = PmModel.find(params[:pm_model_id])
    params[:number] && @pm_version = @pm_model.versions.find_by_number(params[:number])
    params[:id] && @pm_version= PmVersion.find(params[:id])
    params[:from_id]&&@from_version = PmVersion.find(params[:from_id]) 
    if act = params[:go]
      xml = case act
      when "left" then @pm_version.xml
      when "right" then @from_version.xml
      when "merge" then @diff.merge.content
      else
        raise "error"
      end
      return render(:text => xml.html_decode)
    end
    
    respond_to do |format|
      format.html{}
    end
  end
  
end
