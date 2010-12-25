class PmLink < ActiveRecord::Base

  module Extension
	  def pages
	  	map(&:bm)
	  end

	  def not_merged
  	  all.select{|e|e.status!=:link}
	  end
  end
  #pm_model_id of linked lib
  belongs_to :model, :class_name => "PmModel", :dependent => :destroy
  belongs_to :pm_lib, :class_name => "PmLib", :foreign_key => "project_id"
  
  #pm_model_id of Base lib
  belongs_to :bm, :class_name => "PmModel"
  
  #pm_model_version_id of Base lib when edited in project
  belongs_to :bm_version, :class_name => "PmVersion"
  belongs_to :user
  
  before_destroy do |record|
    if record.bm.not_imported?
       record.bm.destroy
    end
    
  end
  
  def create_project_copy
    new_model = bm.attributes.except("created_at", "updated_at", "not_imported", "pm_lib_id")
    new_model["pm_lib_id"] = self.project_id
    record = self.build_model(new_model)
    self.transaction do
      record.import_xml(bm.full_xml)
      self.model = record
      self.save!
    end
    record
  end
  
  EDIT_STATUS = {:new => "项目中新建", :edit => "项目中编辑", :link => "项目中引用" }
  def status_text
   EDIT_STATUS[status]
  end
  
  def status
    if edited?
      :edit
    elsif bm.not_imported?
      :new
    else
      :link
    end
  end
  
  def model_in_project
    (self.status == :edit) ? model : bm 
  end
  
  def current_model
  	edited? ? model : bm
  end
  
  def edited?
  	model
  end
    
  class Maker
    attr_accessor :pages
    attr_accessor :pm_lib
    
    def initialize(pages, pm_lib)
      assert pm_lib!=PmLib::BASE
      @pages = pages
      @pm_lib = pm_lib
    end
    
    # make the initialized link
    def make_init!
      exists = []
      @pages.each do|page|
        link =  PmLink.find_or_initialize_by_bm_id_and_project_id(page.id, pm_lib.id)
        if link.new_record?
          link.user = User.current
          link.save
        else
          exists << link
        end
      end
      exists
    end
    
  end
end
