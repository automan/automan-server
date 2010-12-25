require 'pm/rbeautify'
module Pm
  #
  #Parameters: {"pm_id"=>["22", "23"], 
  #             "url"=>["urlPublishType", "urlPublishCategroy"],
  #             "method_22"=>["--"],
  #             "element_22_0"=>["68"], "method_23"=>["--"],
  #             "element_22_1"=>[""], "element_23_0"=>["70"]}
  #             "element_23_1"=>[""], 
  #             "arg_22"=>[""],"arg_23"=>[""], 
  #
  
 class ModelParam
   attr_accessor :url, :id, :step_params, :model
   def initialize(id,url, step_params)
      @id = id
      @url = url
      @step_params = step_params
	  @model = PmModel.find(id)
   end
   
   def class_name(arg)
      model.class_name(arg)
   end
   

 end
 
 class StepParam
   EMPTY_METHOD = "--"
   def initialize(elements, method,arg)
     @element_ids = filter(elements)
     @method = method
     @arg =  filter(arg, EMPTY_METHOD).first
   end
   
   def to_code(prefix=nil)
   	code = elements.map{|e|
   		 e.collection? ? "#{e.name}[0]" : e.name
   	}.push(@method).join(".")
   	
   	if @arg
   		code<<"(#{@arg})" 			
 		end
 		[prefix,code].compact.join(".")+" ##{elements.map(&:title).join("-->")}"
   end
   
   def elements
  	@elements||=PmElement.find_all_by_id(@element_ids.map{|e|e.blank? ? nil : e}.compact)
   end
   
   private
   def filter(array,empty_pattern=nil)
   	Array(array).map{|e|(e.blank?||(empty_pattern&&e.strip==empty_pattern)) ? nil : e}.compact
   end
   
 end
 
 class ParamParser
   attr_accessor :params, :model_params
   def initialize(params)
     @params = params
     @model_params = parse_model_param
   end
   
   private
   def parse_model_param
     params["pm_id"].map_with_index do |id,i|
       ModelParam.new(id, params["url"][i], create_step_params(id))
     end
   end
   
   def create_step_params(model_id)
    element_params_for_model(model_id).map_with_index{|elements,i|
      es = elements.sort{|a,b|a.index<=>b.index}.map(&:id)
      
    	methods = params["method_#{model_id}"]
    	args    = params["arg_#{model_id}"]
    	puts "*"*30
    	puts ">>#{i}"
    	puts "es => #{es}"
    	puts "methods => #{methods.inspect}"
    	puts "args => #{args.inspect}"
      StepParam.new(es, methods[i], args[i])
    }
   end
   
   
   def element_params_for_model(model_id)
   	 result = []
   	 params.each{|k,v|
   	 	if k =~ /^element_#{model_id}_(.+)/   	 		
   	 		step_id, index = $1.split("_")
   	 		result << ElementParam.new(v, step_id, index)
 	 		end
 	 	}
		result = result.group_by(&:step_id).values.find_all{|e|!e.empty?&&e.first.id!=0}
		result.sort{|a,b|(a.first.step_id <=> b.first.step_id) }		
   end
   
 
	 class ElementParam
	 	attr_reader :id, :step_id, :index
	 	def initialize(id, step_id, index)
	 		@id = id.to_i
	 		@step_id = step_id.to_i
	 		@index = index.to_i
	 	end
	 
	 	def inspect
	 		[step_id,index].join("_")+": #{id}"
	 	end
	 end
	  
 end

 class CodeGen
   attr_accessor :model_params
   def initialize(params)
     @model_params = ParamParser.new(params).model_params
   end
   
   def execute
   	  rhtml = ERB.new(File.read(File.dirname(__FILE__)+"/resources/template.erb"))
      Pm::Rbeautify.beautify_string rhtml.result(binding).to_s#.to_gbk   	
   end
   
   def user	
   	 User.current.nickname
   end
   
 end
end