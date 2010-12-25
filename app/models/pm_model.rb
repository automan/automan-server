require 'ostruct'
class PmModel < ActiveRecord::Base
   include Pm::ARExt::PmModelExt
   include PmVersion::Ext
   include Ownerable::ARExt
   attr_accessor :xml_string
	 include Pm::AttrChangeAutoTrack
	 include Pm::Parse 
	 include Pm::CheckDoubleQuotes
	 check_double_quotes :name,:title, :url
   named_scope :imported, lambda { |imported| {:conditions => (imported ? 'not_imported is null' : 'not_imported is not null')}}

	 has_many :pm_links, :foreign_key => "bm_id" , :dependent=>:delete_all, :extend => PmLink::Extension
	 has_one :project_pm_link, :class_name => "PmLink", :foreign_key => "model_id", :dependent=>:nullify
   has_many :versions, :class_name =>"PmVersion", :foreign_key => "model_id",   :order => "number desc", :dependent => :delete_all 
   belongs_to :pm_folder
   belongs_to :pm_lib
   belongs_to :owners                 	 
   has_many :pm_elements, :dependent => :delete_all 
   has_one  :element_root, :class_name => "PmElement", :conditions=>{:parent_id=>nil}
   validates_uniqueness_of :name, :scope => [:pm_folder_id, :pm_lib_id]
   validates_presence_of :name, :title, :pm_folder_id
   validates_format_of :name, :with => /^[A-Z]+[a-zA-Z0-9_]*$/, :message => "必须是合法的ruby class名称（首字母大写，字母开头， 只包含字母数字和下划线）"
   validates_format_of :url, :with => /(^$)|(^(http|https):\/\/)/ix
 
   typed_serialize :properties, OpenStruct

   
   has_attached_file :image, :styles => { :medium => "300x300>", :thumb => "100x100>" }

   before_validation do |record|
    if !record.name.blank?
     	tracking_hash = {"name"=>record.name.dup}
    	record.name = record.name.camelize if record.name  		
  		record.set_track_change_warning(tracking_hash)
  	end
   end
   
   # 1. create Root element
   # 2. 
   #Must after
   after_create do |record|
     record.build_element_root(:name=>"Root", :title=>"Root", :leaf=>false).save_without_validation!
     record.create_first_version_if_needs! if Pm::TrackVersion.track_version?
   end  
   
   track_version
 
   #第一级lock，不允许删除／修改名称
   def leve_1_locked?(pm_lib=self.pm_lib)
    return nil if self.not_imported
    if  pm_lib.base?
      if pm_links.not_merged.count>0
        "已被锁定（项目中被使用到了）,不能删除／更名"
      end
    else
      return "已被锁定，不能更名"
    end
   end
  
   def folder_trace
     self.pm_folder.ancestors.reverse.push(self.pm_folder)
   end  
    
   def namespaces
     self.pm_folder.namespaces.map{|e|e.name}
   end
   
   def full_xml
   		versions.first.xml
   end
   
   def current_version
    versions.first
   end
   
	 def clear_xml_cache
	  Rails.cache.delete(xml_cache_key)
	 end
	  
	 def xml_cache_key
	   "data/pm_model/xml/#{self.id}"
	 end
   
   def win32?
   	 pm_folder&&(pm_folder.win32?||pm_folder.parent_win32?)
   end
   
   def base?
     pm_lib.base?
   end
   
   def bm
    assert !base?
    project_pm_link.bm
   end
   
   def current_pm_lib
     if not_imported?
       pm_links.first.pm_lib
     else
       pm_lib||pm_folder.pm_lib
     end
   end
   
   def merge_not_imported!
     assert not_imported?
     pm_lib_id = not_imported
     self.not_imported = nil
     save!
     PmLib.find(pm_lib_id).increase_version_clear_cache
   end
   
   def merge_without_change
     assert !self.base?
     self.class.transaction do
       self.destroy
     end
   end
   
   def merge_to_base(xml)
    assert !self.base?
    self.class.transaction do
      bm.import_xml(xml)
      self.destroy
    end
   end
   
   
   def import_xml(xml=xml_string,save=true)
     if save
       PmElement.delete_all(["pm_model_id = ? and parent_id is not null",self.id])
     end
     XmlImporter.new(xml,self,{:save=>save}).import
   end
   
   def create_in_project
      project = self.pm_lib
      assert !project.base?
      self.pm_lib = PmLib::BASE
      self.not_imported = project.id
      ok = false
      self.class.transaction do
        link = self.pm_links.build(:project_id => project.id)
        ok = (save && link.save)
      end
      return ok
   end
   
   def sync_pm_lib_id_with_folder
     PmModel.update_all("pm_lib_id = #{pm_folder.pm_lib_id}", :id=>self.id)
   end
    
   def set_if_not_nil(str, value) 
   	return if !self[str].blank?
   	self[str] = value
   end
   
   
   
public
  class FakeIdGenarator
    def self.shared
      @shared||=self.new
    end
    def initialize
      @current = 0
    end
    
    def next
      @current+=1
    end
  end
  class XmlImporter
    attr_accessor :pm_model, :xml_string
    def initialize(xml_string,pm_model, g_options={})
      if !pm_model.element_root
        pm_model.build_element_root
      end
      @xml_string = xml_string
      @pm_model = pm_model
      @g_options = g_options
      @fake_id_genarator = FakeIdGenarator.new
    end
    
    def import(opt={})
      @g_options.merge!(opt)
   	  container = Pm::Parse::ModelContainer.new(xml_string)  	
    	root_model = container.root_model
    	pm_model.set_if_not_nil("name", root_model.type)
    	pm_model.set_if_not_nil("title", root_model.description)
    	
      Pm::TrackVersion.without_track_version do
      	if @g_options[:save]
      	  pm_model.class.transaction{save_all(root_model)}
    	  else
    	    save_all(root_model)
  	    end
  	  end
  	  if @g_options[:save]
      	pm_model.do_track_version
    	else
    	  pm_model.id = @fake_id_genarator.next
      end
  	  pm_model
    end
    
    def save_all(root_model)
      if @g_options[:save]
    	  pm_model.save!
    	else
    	  pm_model.id = @fake_id_genarator.next
  	  end
  	  
    	root_model.sub_models.each{|e|import_model(e, pm_model.element_root,:nocheck=>true)}
  	  save_elements(pm_model.element_root,root_model.elements, :nocheck=>true)
    end
   
   

    def import_model(model_element, parent, options={}) 	
    	  model = model_element.refered_model 

    	  assert model
  	    model_to_save = pm_model.pm_elements.build(element_attributes(model_element, :name => model.type))
        model_to_save.pm_model = pm_model
  	    model_to_save.parent=parent
  	    if model_to_save.title.blank?
  	    	model_to_save.title = "null"
  	    end 
  	    parent.children << model_to_save
  	    if @g_options[:save]
  	      model_to_save.save!
	      else
      	  model_to_save.id = @fake_id_genarator.next
    	  end
    	  assert model.sub_models, "#{model.inspect}"
  	    model.sub_models.each do |e|
  	    	import_model(e, model_to_save, options)
  	    end

  	    save_elements(model_to_save, model.elements,options)
    	  model_to_save
    end

    def save_elements(model_to_save, elements, options={})
        assert model_to_save.class == PmElement
    		elements.each do |e|
    			the_type = if e.type
    				e.type.strip.sub(/^AWatir::/, "")
  				else
  					PmElement::DEFAULT_TYPE
  				end
  	    	element = pm_model.pm_elements.build(element_attributes(e, {:leaf=>true}, 
  	    																				            {:html_type => the_type}))
	    		element.pm_model = pm_model						            
	    		element.parent = model_to_save
	    		model_to_save.children << element							
	    	  assert element.parent
	    	  assert element.pm_model
	    		if @g_options[:save]
    	    	if options[:nocheck]
    	    		element.save_without_validation
    	    	else
    	    		element.save!
    	    	end
  	    	else
        	  element.id = @fake_id_genarator.next
  	      end											  
  	    end
    end
    
    
     def element_attributes(element, attrbutes={}, properties={})
      	props = properties.reverse_merge(:selector   => element.selector,
  																		   	:collection   => element.collection, 	   	
  																		   	:required   => false #TODO zhushi-> taichan, should add this to xml   	 
  																	 	    )
  			attrbutes=attrbutes.reverse_merge(:name  => element.name, 
     	  									 			:title => element.description, 
     	  												:leaf => false)
     	  attrbutes[:properties] = OpenStruct.new(props)
     	  attrbutes
     end
   end
end
