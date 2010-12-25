module PmFoldersHelper
  def link_to_pm_folder_type(pm_folder)
    if pm_folder.parent_win32?
      "父节点为win32,如需修改，请点击其父节点修改"
    elsif pm_folder.win32?
      "这是一个win32目录,如需修改成［Web］类型，请点击#{link_to("此连接", "#", :class=>:win32, :id=>"type-link", "data-id"=>pm_folder.id)}"
    else
      "这是一个Web目录,如需修改成［win32］，请点击#{link_to("此连接", "#", :class=>:web, :id=>"type-link", "data-id"=>pm_folder.id)}"    
end
  end
end
