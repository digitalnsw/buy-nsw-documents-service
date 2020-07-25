Rails.application.routes.draw do
  mount DocumentService::Engine => "/document_service"
end
