module LiveTreeHelper
   def _id_to_javascript(id) #:nodoc:
      id.kind_of?(Numeric) ? id.to_s : ("'" + escape_javascript(id.to_s) + "'");
   end

   def _recurse_live_tree_data(item, depth, get_item_id_proc, get_item_name_proc, get_item_children_proc, get_item_parent_proc, special_child_id = nil, special_child_data = nil) #:nodoc:
      result = "{id:" + _id_to_javascript(get_item_id_proc.call(item)) + ",name:'" + escape_javascript(get_item_name_proc.call(item).to_s) + "'"
      
      if item.respond_to?(:live_tree_item_html_options)
      	opt = item.live_tree_item_html_options
      	result += ", "+opt.map{|k,v|"#{k}:#{_id_to_javascript(v)}"}.join(" ,")
    	end
      
      if get_item_children_proc.call(item).size == 0
         result += ",children:[]"
      elsif depth == nil || depth > 1
         result += ",children:[\n"
         first = true
         for child in get_item_children_proc.call(item)
            result += ",\n" unless first
            first = false
            if get_item_id_proc.call(child) == special_child_id
               result += special_child_data
            else
               result += _recurse_live_tree_data(child, depth == nil ? nil : depth - 1, get_item_id_proc, get_item_name_proc, get_item_children_proc, get_item_parent_proc, special_child_id, special_child_data)
            end
         end
         result += "]"
      end
      result += "}"
      result
   end
   def _get_live_tree_data(item, options, params) #:nodoc:
      options ||= {}
      get_item_id_proc = Proc.new { |x| x.id }
      if options[:get_item_id_proc] != nil
         get_item_id_proc = options[:get_item_id_proc]
      end
      get_item_name_proc = Proc.new { |x|  x.tree_name }
      if options[:get_item_name_proc] != nil
         get_item_name_proc = options[:get_item_name_proc]
      end
      get_item_children_proc = Proc.new { |x| x.children }
      if options[:get_item_children_proc] != nil
         get_item_children_proc = options[:get_item_children_proc]
      end
      get_item_parent_proc = Proc.new { |x| x.parent }
      if options[:get_item_parent_proc] != nil
         get_item_parent_proc = options[:get_item_parent_proc]
      end
      depth = params[:depth] == nil ? nil : params[:depth].to_i
      include_parents = params[:include_parents]
      root_item_id = params[:root_item_id] == nil ? nil : params[:root_item_id].to_i
			
      result = _recurse_live_tree_data(item, depth, get_item_id_proc, get_item_name_proc, get_item_children_proc, get_item_parent_proc)
      if include_parents
         while get_item_parent_proc.call(item) != nil && (root_item_id == nil || get_item_id_proc.call(item) != root_item_id)
            result = _recurse_live_tree_data(get_item_parent_proc.call(item), 2, get_item_id_proc, get_item_name_proc, get_item_children_proc, get_item_parent_proc, get_item_id_proc.call(item), result)
            item = get_item_parent_proc.call(item)
         end
      end
      return result;
   end

   def LiveTreeHelper.live_tree_js_name(name) #:nodoc:
      ActiveSupport::Inflector.camelize(name).sub(/^(.)/) { |s| $1.downcase }
   end

   def live_tree(name, options = {})
      options = options.dup;
      if options[:js_variable_name] != nil
         var_name = options[:js_variable_name]
      else
         var_name = LiveTreeHelper.live_tree_js_name(name)
      end
      options.delete :js_variable_name
      js = "var " + var_name + "=" + construct_live_tree_function(name, options) + ";"
      js += var_name + ".render();"
      return javascript_tag(js);
   end
   def construct_live_tree_function(name, options = {})
      options = options.dup;
      if options[:id] != nil
         tree_id = options[:id]
      else
         tree_id = name
      end
      for k in [:on_click_item, :on_expand_item, :on_collapse_item, :on_load_item]
         if options[k] != nil
            options[k] = "function(item){" + options[k] + "}"
         end
      end
      if options[:data_url] == nil
         if options[:data_action] == nil
            act = name.to_s + "_live_tree_data"
         else
            act = options[:data_action]
         end
         if options[:data_controller] == nil
            options[:data_url] = { :action => act }
         else
            options[:data_url] = { :controller => options[:data_controller], :action => act }
         end
      end
      options[:data_url] = '"' + escape_javascript(url_for(options[:data_url])) + '"'
      for k in [:css_class, :css_style]
         if options[k] != nil
            options[k] = '"' + escape_javascript(options[k]) + '"'
         end
      end
      if options[:root_item_id] != nil
         options[:root_item_id] = _id_to_javascript(options[:root_item_id])
      end
      if options[:initial_data_root] != nil
         item = options[:initial_data_root]
         if (options[:initial_data_whole_tree])
            depth = nil
         elsif (options[:expand_root_item] == nil || options[:expand_root_item] || options[:hide_root_item])
            depth = 2
         else
            depth = 1
         end
				 if options[:initial_data_options] == nil
            data_options_method = controller.method("_#{name}_live_tree_options") rescue nil
            if data_options_method
               data_options = data_options_method.call
            else
               data_options = {}
            end
         else
            data_options = options[:initial_data_options]
         end
         data_options = data_options.dup
         data_options[:depth] = depth;
         options[:initial_data] = construct_live_tree_data(item, data_options)
      end
      options.delete :id
      options.delete :data_action
      options.delete :data_controller
      options.delete :initial_data_root
      options.delete :initial_data_options
      options.delete :initial_data_whole_tree
      options_js = "{\n" + options.map {|k, v| LiveTreeHelper.live_tree_js_name(k) + ":#{v}"}.join(",\n") + "\n}"
      "new LiveTree(\"" + tree_id.to_s + "\"," + options_js + ")"
   end
   def construct_live_tree_data(item, options = {})
      return _get_live_tree_data(item, options, options)
   end
end
