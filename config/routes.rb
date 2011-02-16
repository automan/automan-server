ActionController::Routing::Routes.draw do |map|
  map.home "",  :controller => :pm_libs 
  map.connect "api/pm_models/:id.:format", :controller => :pm_models, :action=>:show
  map.namespace :api do|api|
		api.resources :pm_libs
		api.resources :pm_models
		api.resources :pm_elements
		api.resources :dm_sqls
	end	
	
	map.resources :pm_libs, :collection	=> ["simple_list","monkey_api"], :member=>["close","fav_folder"] do |lib|
    lib.resources :pm_folders do |folder|
    	folder.resources :pm_models
    end
    lib.resources :pm_models, :collection => [:import, :preview],  :member=>["edit_in_project","merge_to_base"]
  end     
  
  map.update_attr 'update_attr', :controller => "home", :action=>"update_attr"
  map.resources :pm_folders, :collection=>["folder_live_tree_data"], :member => ["export", "delete_preview"]

	map.with_options :controller  => "pm_versions"  do|version|
		version.connect '/pm_models/:pm_model_id/version/diff/:number/:from',:action=>"diff"
		version.connect '/pm_models/:pm_model_id/version/:number',:action=>"show"
	end		
  
  map.resources :pm_models, :member=>["diff", "link_status","history"] do |model|
    model.resources :pm_elements
  end
  
  
  map.resources :pm_elements, :collection=>["element_live_tree_data"], :member=>["move"]

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
