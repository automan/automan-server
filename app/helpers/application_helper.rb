# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def breadcrumb(*args)  	
    elements = args.flatten
    elements.any? ? content_tag('span', args.join(' &#187; '), :class => 'breadcrumb') : nil
  end

  # Display a link to user's account page
  def link_to_user(user, options={})
    (user) ? link_to(user.name, :controller => 'admin/users', :action => 'show', :id => user) : 'Anonymous'
  end

  def format_date(date)
    return nil unless date
  	return time_ago_in_words(date)+"前" if true
    # "Setting.date_format.size < 2" is a temporary fix (content of date_format setting changed)
    @date_format ||= (Setting.date_format.blank? || Setting.date_format.size < 2 ? l(:general_fmt_date) : Setting.date_format)
    date.strftime(@date_format)
  end

  def format_time(time, include_date = true, options={})
    return nil unless time 
    if options[:format] == :ago
  		time_ago_in_words(time)+"前"
  	else
  		time.to_s(options[:format]||:db)
		end    
  end
  
  def content_for(name, content = nil, &block)
    @has_content ||= {}
    @has_content[name] = true
    super(name, content, &block)
  end

  def has_content?(name)
    (@has_content && @has_content[name]) || false
  end

  def html_title(*args)     
    if args.empty? && @html_title.nil?
      ""
    else
      @html_title ||= []
      @html_title += args
    end                                            
  end	
	
  def syntax_highlight(name, content)
    Redmine::SyntaxHighlighting.highlight_by_filename(content, name)
  end
  
	def tabs_header(tabs, options={})
		modify_tabs!(tabs)
		container = if options[:container]
			"'#{options[:container]}'"
		else
			'null'
		end
		links =	tabs.map do|tab|                
		  link_options  =  { :id      => "tab-#{tab[:name]}",   
        :class   => (tab[:name].to_s != selected_tab(tabs) ? nil : 'selected') }
		                     
		  tab_option = options[tab[:name]]         
		  onclick_tab_option  = tab_option&&tab_option[:onclick]       
		  default_onclick = "showTab('#{tab[:name]}',#{container} ); this.blur(); return false;"
		  link_options[:onclick] = if onclick_tab_option.nil?         
        default_onclick
      elsif onclick_tab_option.is_a? Hash
        remote_function onclick_tab_option.merge(:after=>"showTab('#{tab[:name]}',#{container} );")
      else
      end
	    "<li>" + link_to(l(tab[:label]), "#", link_options) + "</li>"
		end
		
		%[<div class="tabs">
			<ul>
			    #{links.join("\n")}
			</ul>
		</div>]
	end
	
	def tab_content(tab, tabs, options={}, &block)		 
	  options[:content] ||= capture(&block)	  		
	  
	  modify_tabs!(tabs)
  	tab = if tab.is_a? Integer			
			tabs[tab]
		else
		  tabs.find{|e|e[:name].to_s == tab.to_s}
		end
		
  	result = content_tag(:div, options[:content] , 
      {:id => "tab-content-#{tab[:name]}", :style => (tab[:name].to_s != selected_tab(tabs) ? 'display:none' : nil),
        :class => 'tab-content' }, block)
  	if block_given?
  		concat(result, block.binding)
  	else
  		result
  	end	
	end
	
	def table(collection, headers, options = {}, &proc)
	  options.reverse_merge!({
        :placeholder  => "<p class='nodata'>#{l(:label_no_data)}</p>",
        :class        => "table"
      })
		
		return concat(options[:placeholder], proc.binding)  if collection.blank?
	 	  
	 	output = %[<table #{options[:tag_option]} style="text-align:left;#{options[:style]}" class="list #{options[:class]}">		
			<thead><tr>		
			#{headers.collect { |h| "\n\t" + content_tag('th', h) }.join("\n")}		
			</tr></thead>
			<tbody>]
		concat(output, proc.binding)
    if options[:with_index]    	
  		collection.each_with_index do |row, index|
	      proc.call(row, index, cycle('odd', 'even'))
		  end
  	else  		
    	collection.each do |row|
	      proc.call(row, cycle('odd', 'even'))
		  end
		end
	 	
	    
    concat("</tbody>\n</table>\n", proc.binding)
	end
	
	# Renders flash messages
  def render_flash_messages
    s = ''
    @notice ||= flash[:notice]
    @error  ||= flash[:error]
    
    if @notice
      s<<content_tag('div', @notice, :class => "flash notice")
    end
    
    if @error
      s<<content_tag('div', @error, :class => "flash error")
    end
    s
  end
	
	def link_to_pop_page(name, link_options)
    
	  link_to(name,link_options, {:class=>"popup",:popup=>true})
	end
	
	def infobox(&block)
		concat(%[	<div class="infobox">
    <div class="ex1"><span></span></div>
    <div class="bd">#{capture(&block)}  	
        </div>
     <div class="ex2"><span></span></div>
     </div>], block.binding)
	end
	
	def base64_encoding(str)
		require 'base64'
		Base64.encode64(str)
	end
	  
	def inplace_update_attr(model, att)
	    url = update_attr_url(:id=>model, :model=>model.class, :attr => att)
			%[<span id="#{att}_#{model.id}">#{model.get_attr(att)}</span>
    	<script type="text/javascript" charset="utf-8">			
    		new Ajax.InPlaceEditor('#{att}_#{model.id}', '#{url}');
    	</script>]
	end
	
  def render_facebox  
    if @facebox_rendered.nil?
      @facebox_rendered = true
      render :partial => "shared/facebox"
    else                     
    end
  end
  
  def not_support_ie_message  	
	 if request.env['HTTP_USER_AGENT'] =~ /MSIE/
	 	 %[ <div id="errorExplanation">
	  	本系统暂不支持IE， 请使用 <a href="http://www.mozillaonline.com/">Firefox</a>或 <a href="http://www.google.com/chrome/">Google Chrome</a> 浏览
	  </div>]	  
	 end
  end

	def link_to_help(title)
		url = "http://automan.taobao.net/guides/#{title}"
		link_to "帮助", url, :class=>"icon-help icon22", :popup=>true, :title=>title
  end  
	
	def jquery_script(options={}, &block)
		content = capture(&block)	
		concat(%[
		<script type="text/javascript" charset="utf-8">  
			    jQuery(document).ready(function($) {
						#{content}  		  
		  		});
		</script>], block.binding) 
	end
	
	def span_to_long_title(title, options={})
		options[:length]||=32
		cuted = truncate(title,options.slice(:length))
		if cuted == title
			return title
		end		
		rand
		id = options[:id]||rand(10000)
		id = "long-title-#{id}"
		%[#{link_to_popup(truncate(title,options.slice(:length)), "##{id}", :title => title)}
		<div id ="#{id}" style="display:none;">#{title}</div>]
	end
	
	def link_to_long_title(title, url={}, options={})
		options[:length]||=32
		if options[:popup]
			link_to_popup truncate(title,options.slice(:length)), url, :title => title
		else
			link_to truncate(title,options.slice(:length)), url, :title => title
		end
	end 
	
	def link_to_popup(name,options = {}, html_options = {})
    html_options.merge!(:rel=>"facebox")
		link_to name, options, html_options
	end
  

end
