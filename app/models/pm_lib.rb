class PmLib < ActiveRecord::Base
  BASE_ID = 15
  BASE = self.find(BASE_ID)
  include Ownerable::ARExt
  has_many :pm_folders, :dependent => :destroy
  has_many :pm_models
  has_one  :folder_root, :class_name => "PmFolder", :conditions=>{:parent_id=>nil}
  validates_uniqueness_of :name
  validates_presence_of :title  
  validates_format_of :name, :with => /^[a-zA-Z0-9_-]+$/ , :message => (l :warn_valid_eng_char)
  
  has_many :pm_links, :foreign_key => "project_id", :extend => PmLink::Extension 
  
  alias :origin_folder_root :folder_root
  
  def self.base
    find(BASE_ID)
  end
  
  def name_zh
    base? ? "基线库" : name
  end
  
  def folder_root(folder=nil)
		if base?
			origin_folder_root
		else 
		  Pm::FolderTree.build_tree_for_pm_lib(self,folder)
		end
  end
  
  def export_xml_root
		if base?
		  origin_folder_root
	  else
	    Pm::FolderTree.build_tree_for_pm_lib_not_merged(self)
    end
  end
  
  def close!
    pm_links.destroy_all
    self.updated_at = Time.now
    self.save!
  end
  
  def after_create
    self.build_folder_root(:name=>"Root", :title=>"Root").save_without_validation!
  end
  
  def pm_model_link(pm_model)
    pm_model.pm_links.find_by_project_id(self.id)
  end
  
  def pm_model_status(pm_model)
    return :none if base?
    pm_model_link(pm_model).status
  end
  
  def project_v2?
    self[:project_v2]||true
  end
    
  def full_xml
  	Rails.cache.fetch(xml_cache_key) do
  		YAML.dump(Pm::LibVersion.new(self).version_tree)
	  end
  end
	 
  def base?
  	self.id == PmLib::BASE.id
  end
  
  def increase_version!
    self.updated_at = Time.now
    save_with_validation!
  end
  
  def increase_version_clear_cache
    increase_version!
  	clear_xml_cache
  end
  
  def clear_xml_cache
  	Rails.cache.delete(xml_cache_key)
  end
  
  def xml_cache_key
  	"data/pm_lib/xml/#{self.id}"
  end
end
