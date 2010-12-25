require "pm_lib"
class PmFolder < ActiveRecord::Base      
  TYPE_WEB = 0
  TYPE_WIN32 = 1
	include Pm::AttrChangeAutoTrack
  has_many :pm_models, :dependent => :destroy, :conditions => {:pm_lib_id=>PmLib::BASE.id}
  belongs_to :pm_lib
  
  validates_presence_of :name, :title  
  validates_uniqueness_of :name, :scope=>[:parent_id]
  validates_format_of :name, :with => /^[A-Z]+[a-zA-Z0-9_]+$/, :message => "必须是合法的ruby module名称，（首字母大写， 只包含字母数字和下划线）"
  acts_as_tree    
  track_version
  before_update do|record|
  	if record.changed.include?("name")
  		record.pm_models.each{|e|e.clear_xml_cache}
		end
  end
  
  include Pm::CheckDoubleQuotes
  check_double_quotes :name,:title

  before_validation do |record|
	  tracking_hash = {"name"=>record.name.dup}
  	record.name = record.name.camelize if record.name
		record.set_track_change_warning(tracking_hash)
  end
  
  def viewable_pm_models
    pm_models.imported(true)
  end
  
  def all_pm_links
    models = self.all_children.empty? ? pm_models : all_children.map(&:pm_models).flatten
    if models.empty?
      []
    else 
      PmLink.all(:conditions => {:bm_id=>models.map(&:id)})
    end
  end
  
  def name
  	if self.root?
  		pm_lib.name
		else
  	  super 
  	end   	 
  end
  
  def tree_name
  	name
	end        
  
	def toogle_type(from)
		return "请修改父目录" if parent_win32?
		
    if from == "web" && !win32?
    	self.folder_type = TYPE_WIN32
    elsif from == "win32" && win32?
    	self.folder_type = TYPE_WEB
    else
    	return "Error"
    end
    return nil
	end
  
  def namespaces
    result = ancestors.reverse.push(self)
    result.shift
    result
  end
  
  def win32? 
    self.folder_type == TYPE_WIN32
  end
  
  def parent_win32?
    self.ancestors.any?{|e|e.win32?}
  end
  
  
  before_create do |record|
    if record.pm_lib_id.nil? && record.parent
      record.pm_lib_id = record.parent.pm_lib_id
    end
  end
  
  ## see LiveTreeHelper
  def live_tree_item_html_options
    {:nocheckbox=>true}
  end
  
end
