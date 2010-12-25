module PmModelsHelper 
  
  def link_to_delete_base_pm_model(model)
    if model.pm_links.size > 0
      ""
    else
      link_to "删除" ,pm_model_path(model, :project=>@pm_lib), :confirm => '您确定要删除?', :method => :delete
    end
  end
  
  def pm_folder_options_for_select(pm_lib, options = {})
    s = ''
    if options[:include_blank]
      s = %[<option value="">请选择</option>]
    end
    traval_tree(pm_lib.folder_root, options.slice(:stop_object, :no_root)) do |pm_element, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      tag_options = {:value => pm_element.id, :selected => ((pm_element == options[:selected]) ? 'selected' : nil)}
      tag_options.merge!(yield(pm_element)) if block_given?
      s << content_tag('option', name_prefix + h(pm_element.name), tag_options)
    end
    s
  end 


  def pm_model_options_for_select(pm_lib, value)
    group = pm_lib.pm_models.map{|e|[e.pm_folder.namespaces.map(&:name),e]}.group_by{|e|e.first}
    group = group.map{|k,v|PmOption.new(k,v.map{|e|e.last})}
    option_groups_from_collection_for_select(group,:pm_models,:group_name,:id, :name , value)
  end

  
  
  def pm_element_options_for_select(pm_model, options = {})
    s = ''
    traval_tree(pm_model.element_root, options.slice(:stop_object)) do |pm_element, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      tag_options = {:value => pm_element.id, :selected => ((pm_element == options[:selected]) ? 'selected' : nil)}
      tag_options.merge!(yield(pm_element)) if block_given?
      s << content_tag('option', name_prefix + h(pm_element.name), tag_options)
    end
    s
  end 
  
  
  class PmOption
    attr_reader :group_name, :pm_models
    def initialize(group_name, pm_models)
      @group_name = group_name
      @pm_models = pm_models
    end
    
    
  end
  
  #PmModel & pm_link status
  def link_to_pm_model_link_status(pm_model)
  	if pm_model.not_imported? 
  		"项目中新建"
		else
			if(count = pm_model.pm_links.count) > 0
				link_to_popup "#{count}个项目", link_status_pm_model_path(pm_model)
			else
				"无"
			end
			
		end  	
  end
  
  def tree_options_for_select(root, options={})
    s = ''
    value_key = options[:value_key]||"id"
    traval_tree(root, options) do |element, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      tag_options = {:value => element[value_key], :selected => options[:selected] && ((element[value_key] == options[:selected][value_key]) ? 'selected' : nil)}
      s << content_tag('option', name_prefix + h(element.name), tag_options)
    end
    s
  end
  
  def traval_tree(element, options={}, &block)
  	return  if options[:stop_object] && element.id == options[:stop_object].id
  	level = options[:level]||0
  	
		children = if(proc = options[:children_proc])
		    proc.call(element)
		  else
		    element.children
	    end
	  
    if options[:no_root]&&(element.root?)
      level = -1
    else
      block.call element, level
    end

	    
		if(!children.empty?)
			children.each{|e|
			  	traval_tree(e, options.merge(:level => level+1), &block)}
		end
	end

end
