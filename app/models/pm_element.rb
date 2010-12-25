class PmElement < ActiveRecord::Base
	include Pm::ARExt::PmElementAttr
	include Pm::AttrChangeAutoTrack
  belongs_to :pm_model
  acts_as_tree :order=>"position"
  
  typed_serialize :properties, OpenStruct
  track_version    
  
  include Pm::CheckDoubleQuotes
  check_double_quotes :name,:title, "properties.selector"
  
  validates_presence_of :name, :title  
  validates_uniqueness_of :name, :scope => [:parent_id]
 	
  named_scope :sub_models, :conditions=>{:leaf => false}
  named_scope :elements, :conditions=>{:leaf => true}        
  HTML_TYPES = [["默认", "AElement"], 
                 ["未知(待定)", "Unknown"], 
                 ["Button", "AButton"], 
                 ["Radio", "ARadio"], 
                 ["CheckBox", "ACheckBox"], 
                 ["Link", "ALink"], 
                 ["TextField", "ATextField"], 
                 ["SelectList", "ASelectList"],                 
                 ["no_wait", "ANoWaitElement"],
                 ["alipay password", "AlipayPassword"],
                 ["rich_text", "AInnerTextSetElement"],  
                 ["do_click[IFD项目专用]","ADoClickElement"]]
                 
  WIN32_TYPES = [["默认", "WinElement"],
  							 ["文本框", "WinTextField"],
  							 ["密码框", "WinWWPassword"]]
  							
  WIN32_TYPE_PREFIX = {"WinTextField" => "txt",
  										 "WinWWPassword" => 'txt'}		
  					
  HTML_TYPE_PREFIX = {
  	"AButton" => "btn",
  	"ARadio" => "rad",
  	"ACheckBox"=> "chk",
  	"ALink"=>   "lnk",
  	"ATextField"=>  "txt",
  	"ASelectList"=> "lst",
  	"AInnerTextSetElement"=> "txt",
  	"AlipayPassword"=> "txt" }
  	
  DEFAULT_TYPE = HTML_TYPES.first.last               
  #保存时， 检测输入是否正确	               
  validate :must_valid_on_save
	
  before_validation do |record|
  	return if record.name.nil?
  	tracking_hash = {"name"=>record.name.dup, "properties.selector"=>record.properties.selector.dup}

		if record.new_record?
  		record.name = record.name.underscore 
  		# issue #209
  		if record.properties.collection == "true"
  			record.name = record.name.pluralize 
			else
				record.name = record.name.singularize 
			end
		end
		
		if (selector = record.properties.selector)
			record.properties.selector = selector.gsub(/[\ \ ]+/," ").strip
		end
		record.compute_prefix		
		record.set_track_change_warning(tracking_hash)
  end
  
  alias :old_pm_model :pm_model
  def pm_model
      old_pm_model||parent.pm_model
  end
  
  def move_to!(element)
  	self.parent_id = element.id
  	self.save!
  	if element.leaf
  		element.leaf = false
  		element.save!
		end
  end
  
  def compute_prefix
  	should_be = prefix_pool[self.properties.html_type]
  	return if should_be.nil?
  	splits = self.name.split("_")
  	now = splits.first  	
  	if splits.size>1 && prefix_pool.values.include?(now) && now!=should_be
  		splits[0] = should_be
  		self.name = splits.join("_")
  	elsif now!=should_be
  		self.name = [should_be, name].join("_")
		end
  end
  
	def must_valid_on_save
		return if self.root?      
    errors.add(:name, "必须是合法的ruby method名称，（首字母小写，字母开头， 只包含字母数字和下划线）") unless /^[a-zA-Z]+[a-zA-Z0-9_]*$/ =~ self.name
           
		errors.add("selector", "格式错误，不允许出现双引号\"") if self.properties.selector =~ /\"/
	end
                 
  def html_types
  	if pm_model.win32?
    	WIN32_TYPES
    else
    HTML_TYPES
  end    
  end    
  
  def sub_model?
    !self.leaf
  end
  
  
  def after_initialize
  	#缓存   
  	return false unless(defined? properties)
    if properties.cache.blank?
      properties.cache = false
    end  
    #集合
    if properties.collection.blank?
      properties.collection = false
    end    
    #必填
    if properties.required.blank?
      properties.required = false
    end      
  end
  
  before_create do |record|
    if record.pm_model_id.nil? && record.parent
      record.pm_model_id = record.parent.pm_model_id
    end
  end
                
  
  def traces
    result = ancestors.reverse.push(self)
    result
  end
  
  def root?
    parent.nil?
  end
  
  def name
  	if self.root?
      pm_name
    else     
      super
    end
  end
  
  def zh_name
  	if self.root?
  		pm_model.title
		else
			self.title
		end
  end
  
    
  def title
  	if self.root?
      pm_title
    else     
      super
    end
  end
  
  def pm_name
     pm_model.name
  end
    
  def pm_title
     pm_model.title
  end
  
  def live_tree_item_html_options
  	clazz = if self.root?
  		"root"
		elsif self.sub_model?
			"sub-model"
		elsif self.properties.html_type == "unknown"
			"unknown"
		else
			prefix_pool[self.properties.html_type]||"default"
		end
		{:cssClass=>clazz}
  end
  
  def tree_name(mode="en")
  	if mode == "en"
    	name
  	else
  		zh_name
		end
  end        
  
  def prefix_pool  	
  	pm_model.win32? ? WIN32_TYPE_PREFIX : HTML_TYPE_PREFIX
end
  
end
