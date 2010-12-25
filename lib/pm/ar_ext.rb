require 'pm/html_methods'
module Pm
	module ARExt
	 
		module PmModelAttr
			def model_attr
				[["IsWeb", !win32?], 
				 ["base", win32? ? "WinModel" : "HtmlModel"], 
				 ["modelNamespace", namespaces.join("::")], 
				 ["controltypeNamespace", "AWatir"]].build_ordered_hash
			end    
			
			def automan_class_name
			  name
			end
		end
		
		module PmElementAttr
		  include Pm::HtmlMethods
		  
		  def collection?
		  	self.properties&&self.properties.collection == "true"
		  end
		  
			def method_attr                     
			   the_type =  if self.sub_model?        
			     model_type
		     else
			     automan_html_type(properties.html_type)
	       end
				 [["name", name],
				  ["type", the_type],
				  ["description", title],
				  
					["selector", properties.selector],
					["collection", properties.collection],
					["cache", "false"]].build_ordered_hash
			end
			
			def html_methods
        # if self.properties.collection == "true"
        #   return []
        #         end
			  if sub_model?
			    ElementType.submodel_type.html_methods
		    else
  			  (ElementType.find_by_name(self.properties.html_type)||ElementType.base_type).html_methods
	      end
			end
			
			def model_attr
				result = if self.root?
					[["type", self.pm_model.automan_class_name], ["Root", "true"], ["url", self.pm_model.url]]
				else
					#assert !self.leaf?				
				  [["type", model_type], ["Root", "false"]]
				end
				
				(result << ["description", self.title]).build_ordered_hash
			end                
      
			
			protected     
			
			def model_type
			  assert self.sub_model?	
			  # fix 949		  
			  (self.name.sub(/.*\./, '')).camelize
			end
			
			def automan_html_type(html_type)
			  "AWatir::#{html_type}"
			end
		end
		
		module PmModelExt
		 include Pm::ARExt::PmModelAttr
	   def included(base)
	   		base.send :include, ActionController::UrlWriter
	 	 end
	 	 
	 	 def class_name(with_namespace = false)
	 	   if with_namespace
	 	     [namespaces,class_name].join("::")
 	     else
	 	     self.name
       end
	 	 end
	 	 
	   def xml_render
	   	Pm::XmlRender.new(self)
	   end	   
	
	   def xml_file_name
	     "#{name}.xml"
	   end         
	 
	   def xml_file_url
	     api_pm_model_url(self, :format=>"xml")
	   end
	  end
	  
	end
end