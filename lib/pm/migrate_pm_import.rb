class MigratePmImport
  def self.go
    go_for_pm_model_lib_id
    go_for_first_pm_version
  end
  
  def self.go_for_first_pm_version
    PmVersion.delete_all
    PmModel.all.each{|e|e.send :create_first_version_if_needs!}
  end
  
  def self.go_for_pm_model_lib_id
    PmLib.all.each{|e|
      if e.id != 15
        e.destroy
      end
    }
    PmModel.update("pm_lib_id = 15")
  end
end