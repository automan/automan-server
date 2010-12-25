require "acts/active_record/list"
require "acts/active_record/typed_serialize"
require "acts/active_record/tree"
require "acts/controller/live_tree"   
require "extensions/all"
ActiveRecord::Base.send :include,  Acts::ActiveRecord::List  
ActiveRecord::Base.send :include,  Acts::ActiveRecord::Tree       
ActiveRecord::Base.send :include,  Acts::ActiveRecord::AutoIncrement       
ActiveRecord::Base.send :include,  Pm::TrackVersion    
ActionController::Base.send :include, Acts::Controller::LiveTree

module Api
end

Api::PmLibsController     = PmLibsController
Api::PmModelsController   = PmModelsController
 
ActiveRecord::Base.send :include,  ActionController::UrlWriter

ActiveRecord::Base.default_url_options = {:host => "localhost", :port=>"3000"}

GLoc.set_config :default_language => :zh
GLoc.clear_strings
GLoc.set_kcode
GLoc.load_localized_strings
GLoc.set_config(:raise_string_not_found_errors => false)
include GLoc
Time::DATE_FORMATS[:stamp] = '%y%m%d%H%M%S'

I18n.default_locale = :zh