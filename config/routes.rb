Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "dashboard", to: "dashboard#index"
  resources :posts
  resources :video_creations, only: %i[index new create show]
  resources :projects
  resources :project_photos, only: %i[new create]
  resources :zernio_accounts, only: %i[create destroy]
  resources :slideshows, controller: "slideshow_imports", as: :slideshow_imports, only: %i[index new create show] do
    post :start, on: :member
  end
  root to: "dashboard#index"
  get "sign_up", to: "registration#new"
  post "registration", to: "registration#create"
end
