module Pm::HtmlMethods
	METHODS_DEF = {:Model    => {:exist? => 0, :empty? => 0, :text => 0 },
	               :AElement => {:click => 0, :text => 0, :get  => 1, 
															 :get_properties =>0 ,:focus=>0, :visible=>0,
															 :outer_html=>0,:fire_event=>1 },
        				 :ATextField => {:set => 1, :readonly=>0,  :readonly= => 1},
        				 :ALink      => {:click => 0 },
        				 :ACheckBox  => {:set => 0, :clear => 0, :checked => 0 },
        				 :ARadio     => {:set => 0, :clear => 0, :checked => 0 },
        				 :ASelectList =>{:options => 0, :set  => 1, :selected_value => 0 },
        				 :AButton => {},
        				 :AlipayPassword => {:set=>1},
        				 :AInnerTextSetElement => {:set=>1}
      				 }
        				 
  class HtmlMethod
    attr_accessor :name, :arg
    def initialize(name,arg)
      @name= name
      @arg = arg
    end
  end

  class ElementType
    attr_accessor :name
    def initialize(name, methods)
      @name = name
      @_methods = methods.map{|n,args|HtmlMethod.new(n, args)}
    end
  
    def html_methods
      if [:AElement, :Model].include?(self.name.to_sym)
        return @_methods
      else
        @_methods + self.class.base_type.html_methods 
      end
    end
  
    class << self
      attr_reader :register

      def base_type
        find_by_name(:AElement)
      end
    
      def submodel_type
        find_by_name(:Model)
      end
      
      def find_by_name(_type)
        register.find{|e|e.name.to_s == _type.to_s}
      end
    
      def __create_register
        @register = Pm::HtmlMethods::METHODS_DEF.map{|k,v|ElementType.new(k,v)}
      end
    end
  end
end
Pm::HtmlMethods::ElementType.__create_register
