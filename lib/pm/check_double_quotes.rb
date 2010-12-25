module Pm
	module CheckDoubleQuotes 
	  def self.included(base)
	     base.extend(ClassMethods)
	  end
	  
	  module ClassMethods
	    def check_double_quotes(*fields)     
	       include InstaceMethods
	       class_inheritable_reader(:check_dq_conf)
	       write_inheritable_attribute(:check_dq_conf, fields)
	       validate :check_double_quotes
	    end
	  end
	  
	  module InstaceMethods
	    
	    def check_double_quotes      
	       ok = true
	       check_dq_conf.each do |field|
	         if self[field]=~/\"/
	           errors.add(field, "包含非法字符 '\"'")
	           ok = false
	           break
           end
	       end         
	       return ok       
	    end
	    
	  end
		
	end  
end