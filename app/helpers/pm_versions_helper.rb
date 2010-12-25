module PmVersionsHelper
   def pm_model_version_path(model,action,options={})
    number = options.delete(:number)
    from = options.delete(:from)
    param = from.nil? ? "" : "/#{number}/#{from}"
    url = "/pm_models/#{model.id}/version/#{action}#{param}"
    options&&options.except!(:number,:from)
    if options&&!options.empty?
      url += "?#{options.to_query}"
    end
    url
   end
end