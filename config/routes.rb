DocumentService::Engine.routes.draw do
  resources :documents, only: [:create, :show, :index] do
    get :can_attach, on: :collection
  end

  resources :avatars, only: [:create, :show]

  resources :upload, only: [] do
    post :upload_suppliers, on: :collection
    post :upload_tenders, on: :collection
  end
end