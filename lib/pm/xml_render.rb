module Pm	
    class XmlRender
    	attr_reader :builder
    	def initialize(pm_model)
    		@pm_model  = pm_model
    		@element_root = pm_model.element_root
    		@builder = Builder::XmlMarkup.new(:indent=>2, :margin=>4)
    	end
	
    	def to_xml
    		xml = builder.models(@pm_model.model_attr){
    			write_model(@element_root)
					@element_root.all_children.each do|e|
						 if e.sub_model?
						 	write_model(e)
					 	 end
					end
				}
				
     	end
    	
    	private
    	def write_model(m)
	      builder.model(m.model_attr){
	  			m.children.sub_models.each do|sub_m|
	  				builder.subModel(sub_m.method_attr)
	  			end              
	  			
				  m.children.elements.each do|e|
	  				builder.element(e.method_attr)
	  			end
			 }
			end
    end
end
