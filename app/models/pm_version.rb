require "htmlentities"
class PmVersion < ActiveRecord::Base
  belongs_to :model, :class_name => "PmModel"
  belongs_to :pm_lib, :class_name => "PmLib", :foreign_key => "project_id"
  belongs_to :parent, :class_name => "PmVersion"
  belongs_to :user
  acts_as_autoincrement :number, :scope => :model_id

  before_create do |record|
    record.user = User.current
  end
  
  def diff(from)
    assert from.class == self.class, "#{from} type should be #{self.class} but was:#{from.class}"
    return PmDiff.new(self, from) 
  end

  def get_diff_title_prefix
    @diff_title_prefix
  end
  
  def diff_title_prefix(prefix)
    @diff_title_prefix = prefix
    self
  end
  
  module Ext
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.send :__versionable
    end
    
    module InstanceMethods
      
      def diff(version_to, version_from=nil)
        if version_from.nil?
          version_from = version_to
          version_to = self.current_version.number
        end
        version_to=version_to.to_i
        version_from=version_from.to_i
        
        assert version_to!=version_from, "#{version_to} vs #{version_from}"
        to = self.versions.find_by_number(version_to)
        from = self.versions.find_by_number(version_from)
        to.diff(from)
      end
      
      def current_version
        versions.first
      end
    end

    module ClassMethods
      def __versionable
         has_many :versions, :class_name=>"PmVersion", :dependent => :delete_all, :foreign_key => "model_id"
      end
    end
    
    def create_version_if_changed!
      original_xml = versions.first.xml
      if xml_changed(original_xml, inner_to_xml)
        inner_create_version!(:xml => inner_to_xml)
        return true
      end
      return false
    end
    
    def create_first_version_if_needs!
      if versions.first
        return false 
      else
        inner_create_version!(:xml => inner_to_xml)
        return true
      end
    end
    
    def inner_to_xml
      self.xml_render.to_xml
    end
    
    def inner_create_version!(options)
      versions.create!(options.merge(:user => User.current))
    end
    
    def xml_changed(xml1, xml2)
      !(xml1 == xml2)
    end
    
  end
  
end



class PmMergeResult
  attr_accessor :content, :conflict
  def initialize(content, conflict)
    @content = content
    @conflict = conflict
  end
end

class PmDiff
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper 
  FILE_PREFIX = "#{RAILS_ROOT}/tmp/diff"
  def initialize(version_to, version_from)
    @version_to = version_to
    @version_from = version_from
  end
  
  def same?
    diffs.empty?
  end
  
  def diffs
    @diffs||=begin
      to_path, from_path = write_diff_files
      diff_raw = `diff -uwB #{from_path} #{to_path} `.chomp
      Redmine::UnifiedDiff.new(diff_raw)      
    end
  end
  
  def left_header
    header_of_version(@version_from)
  end
  
  def right_header
    header_of_version(@version_to)
  end
  
  def merge
    to_path, from_path = write_diff_files
    mk_merge_file
    conflict = !`merge #{FILE_PREFIX}.merge #{to_path} #{from_path} 2>&1`.chomp.blank?
    merged = File.read("#{FILE_PREFIX}.merge")
    PmMergeResult.new(merged, conflict)
  end
  
  
  private
  
  def header_of_version(version)
    "#{version.get_diff_title_prefix}#{links_of(version)}"
  end
  
  def links_of(version)
    pm = version.model
    pm_path = "/pm_models/#{pm.id}"
    version_path = "#{pm_path}/version/#{version.number}"
    "#{link_to(pm.name,pm_path)}##{link_to(version.number,  version_path)}(#{version.user},#{version.created_at.to_s(:db)})"
  end
  
  def mk_merge_file
    `echo > #{FILE_PREFIX}.merge`
  end
  
  def write_diff_files
    File.open("#{FILE_PREFIX}.to","w"){|e|e<<xml_content(@version_to)}
    File.open("#{FILE_PREFIX}.from","w"){|e|e<<xml_content(@version_from)}
    ["#{FILE_PREFIX}.to", "#{FILE_PREFIX}.from"]
  end
  
  def xml_content(version)
    version.xml.html_decode
  end
end