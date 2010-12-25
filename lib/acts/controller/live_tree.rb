module Acts #:nodoc:
   module Controller
    module LiveTree
       def self.included(base)
          base.extend(ClassMethods)
       end
       module ClassMethods

          def live_tree(name, options = {})   
             include InstanceMethods
             raise ":model, :model_class_name, or :find_item_proc option is required" if options[:model] == nil && options[:model_class_name] == nil && options[:find_item_proc] == nil
             if options[:model_class_name] != nil
                model = options[:model_class_name]
             else
                model = ActiveSupport::Inflector.camelize(options[:model])
             end
             self.const_set("LIVE_TREE_OPTIONS_" + name.to_s.upcase, options);
             code = "" +
             "def _#{name}_live_tree_options\n" +
             "    LIVE_TREE_OPTIONS_" + name.to_s.upcase + "\n" +
             "end\n" +
             "def _#{name}_find_live_tree_item\n" +
             (options[:find_item_proc] == nil ?
             ("    " + model + ".find(self.live_tree_item_id)\n") :
             ("    _#{name}_live_tree_options[:find_item_proc].call(live_tree_item_id)\n")) +
             "end\n" +
             "def #{name}_live_tree_data\n" +
             "    get_live_tree_data(_#{name}_find_live_tree_item, _#{name}_live_tree_options)\n" +
             "end\n"
             class_eval code
          end
       end  
       
       module InstanceMethods  
       
         def setup_item_type_tree(check_get=false)
        	  return if check_get&&!request.get?
          	@root=ItemType.root    
         end
       
         # Returns the value of the item ID from the request's params.
         def live_tree_item_id
             params[:item_id]
         end
         def get_live_tree_data(item, options = {})
            #Kernel.sleep(10); #XXX
            render :inline => '<%= _get_live_tree_data(item, options, params) %>', :locals => { :item => item, :options => options }
         end
       end    
       
       
    end
   end
end