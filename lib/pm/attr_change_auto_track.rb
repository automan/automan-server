module Pm::AttrChangeAutoTrack
  attr_reader :track_change_warning
  def set_track_change_warning(tracking_hash)
  	result = tracking_hash.map{ |k,v| 
  		methods = k.split(".")
  		new_v = self
  		while(m = methods.shift)
  			new_v = new_v.send(m)
  		end
  		
  		if new_v != v
  			[k,v,new_v]
			else
				nil
			end
		}.compact
				
		if !result.empty?
			result = result.map{|k,v,new_v|%[字段#{k.split(".").last}从"#{v}"自动保存为"#{new_v}"]}
			@track_change_warning =  %[注意：#{result.join("<br>")}！]
		end
  end
end