module DocumentService
  class Engine < ::Rails::Engine
    isolate_namespace DocumentService
    config.generators.api_only = true
  end
end
