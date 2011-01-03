class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table "ownerables", :force => true do |t|
       t.integer  "user_id"
       t.string   "object_type"
       t.integer  "object_id"
       t.integer  "the_type",    :default => 0
       t.datetime "created_at"
       t.datetime "updated_at"
     end

     add_index "ownerables", ["object_type", "object_id"], :name => "user_object_index"

     create_table "pm_elements", :force => true do |t|
       t.string   "name"
       t.string   "title"
       t.integer  "pm_model_id"
       t.boolean  "leaf",          :default => true
       t.integer  "parent_id"
       t.text     "properties"
       t.datetime "created_at"
       t.datetime "updated_at"
       t.text     "user_comments"
       t.integer  "position"
     end

     add_index "pm_elements", ["parent_id"], :name => "parent_id_index"
     add_index "pm_elements", ["pm_model_id"], :name => "pm_model_id"

     create_table "pm_folders", :force => true do |t|
       t.string   "name"
       t.string   "title"
       t.integer  "parent_id"
       t.integer  "pm_lib_id"
       t.boolean  "leaf"
       t.datetime "created_at"
       t.datetime "updated_at"
       t.integer  "position"
       t.integer  "folder_type", :default => 0
     end

     add_index "pm_folders", ["parent_id"], :name => "parent_id"
     add_index "pm_folders", ["pm_lib_id"], :name => "pm_lib_id"

     create_table "pm_libs", :force => true do |t|
       t.string   "name"
       t.string   "title"
       t.integer  "owner_id"
       t.string   "project_id"
       t.datetime "created_at"
       t.datetime "updated_at"
     end

     create_table "pm_links", :force => true do |t|
       t.integer  "model_id"
       t.integer  "project_id"
       t.integer  "user_id"
       t.integer  "bm_id"
       t.integer  "bm_version_id"
       t.datetime "created_at"
       t.datetime "updated_at"
     end
     
     add_index "pm_links", ["project_id"], :name => "project_id"
     add_index "pm_links", ["model_id"], :name => "model_id"
     add_index "pm_links", ["bm_id"], :name => "bm_id"
     
     create_table "pm_models", :force => true do |t|
       t.string   "name"
       t.string   "title"
       t.integer  "pm_folder_id"
       t.text     "properties"
       t.datetime "created_at"
       t.datetime "updated_at"
       t.string   "url"
       t.string   "image_file_name"
       t.string   "image_content_type"
       t.integer  "image_file_size"
       t.datetime "image_updated_at"
       t.text     "user_comments"
       t.integer  "not_imported"
       t.integer  "pm_lib_id"
     end
     
     add_index "pm_models", ["pm_folder_id"], :name => "pm_folder_id"
     add_index "pm_models", ["pm_lib_id"], :name => "pm_lib_id"
     add_index "pm_models", ["not_imported"], :name => "not_imported"
     

     create_table "pm_versions", :force => true do |t|
       t.integer  "model_id",   :null => false
       t.integer  "parent_id"
       t.integer  "user_id"
       t.integer  "number",     :null => false
       t.string   "message"
       t.text     "xml"
       t.datetime "created_at"
       t.datetime "updated_at"
     end

     add_index "pm_versions", ["model_id"], :name => "model_id"
     add_index "pm_versions", ["model_id","number"], :name => "model_id_number"
     
     create_table "user_favs", :force => true do |t|
       t.integer  "user_id"
       t.integer  "object_id"
       t.string   "object_type"
       t.string   "fav_type"
       t.integer  "position"
       t.datetime "created_at"
       t.datetime "updated_at"
     end

     add_index "user_favs", ["user_id", "object_id", "object_type"], :name => "user_id"
     add_index "user_favs", ["user_id", "object_type"], :name => "user_id_type_index"
     add_index "user_favs", ["user_id"], :name => "user_id_index"

     create_table "users", :force => true do |t|
       t.string   "login"
       t.string   "nickname"
       t.string   "realname"
       t.string   "password"
       t.integer  "disabled",                  :default => 0, :null => false
       t.datetime "created_at"
       t.datetime "updated_at"
       t.string   "email"
       t.integer  "admin",        :limit => 1
       t.string   "department"
       t.integer  "report_to_id"
       t.text     "config"
     end

     add_index "users", ["login"], :name => "login", :unique => true
     create_init_data
  end
  
  def self.create_init_data
    now = Time.now.to_s(:db)
    ActiveRecord::Base.connection.execute("INSERT INTO `pm_libs` (`id`,`name`,`title`,`owner_id`,`project_id`,`created_at`,`updated_at`) VALUES (15, 'Base', '基线库', NULL, NULL, '#{now}', '#{now}');")
    PmLib.first.send :after_create
    User.create!(:login=>"admin",:nickname => "管理员", :email => "come2u@gmail.com")
  end

  def self.down
    drop_table :users
    drop_table :user_favs
    drop_table :pm_versions
    drop_table :pm_models
    drop_table :pm_libs
    drop_table :pm_links
    drop_table :pm_folders
    drop_table :pm_elements
    drop_table :ownerables
  end
end
