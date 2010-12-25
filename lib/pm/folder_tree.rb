module Pm
	class FolderTree
		
    def self.build_tree_for_pm_lib(pm_lib, folder=nil)
      inner_build(pm_lib,pm_lib.pm_links, folder)
    end
    
    def self.build_tree_for_pm_lib_not_merged(pm_lib, folder=nil)
      inner_build(pm_lib,pm_lib.pm_links.not_merged, folder)
    end
    
    private
    def self.inner_build(pm_lib, pm_links, folder)
        result = TreePool.new(PmLib::BASE.folder_root,pm_links)
      	result.pm_lib = pm_lib
      	if folder
      		result[folder.id]
    		else
    			result.root
  			end
    end
	end
	
	class TreePool
    attr_accessor :root, :pm_links
    attr_accessor :hash_pool
    attr_accessor :pm_lib
    
    def initialize(root, pm_links, pool={})
      @root = MemFolder.new(root, self)
      @pm_links = pm_links
      @hash_pool = pool
      add_folders
    end
    
    def add(folder)
    	 @hash_pool[folder.id] = MemFolder.new(folder, self)
    end
    
    def children_of(item)
      @hash_pool.values.select{|v|v.parent&&(v.parent.id == item.id)}
    end
    
    def parent_of(item)
      self[item.pm_folder.parent_id]
    end
    
    def inspect
      "<TreePool @hash_pool=>#{@hash_pool.keys.inspect}, @root=>#{@root.id}>"
    end
    
    def [](id)
      @hash_pool[id]
    end
    
    private
    
    def add_folders
      all_folders_except_root.each{|e|self.add(e)}
    end
    
 	  def all_folders_except_root
	  	result = []
      pm_links.map(&:bm).each{|e|
      	result << e.pm_folder
      	e.pm_folder.ancestors_except_root.each{|f|
	      	result << f
    		}
    	}
    	result
	  end
  end

  class MemFolder 
    attr_accessor :pm_folder, :tree_pool
    def initialize(pm_folder, pool)
      @pm_folder = pm_folder
      @tree_pool = pool
    end
    
    def parent
      @parent||=tree_pool.parent_of(self)
    end
    
    def id
      @pm_folder.id
    end
    
    def pm_lib
    	tree_pool.pm_lib
    end
    
    def pm_models
  		pm_links.map(&:model_in_project)
    end
    
    def pm_links
      @tree_pool.pm_links.select{|e|e.model_in_project.pm_folder_id == self.id}
    end
    alias :viewable_pm_models :pm_models
    
    def children
      @chlidren||=tree_pool.children_of(self)
    end    
    
    def inspect
    	@pm_folder.inspect
    end
    
    private
    
		def method_missing(name, *args, &block)
			@pm_folder.send(name, *args,&block)
		end
  end
end