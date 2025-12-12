Rails.application.routes.draw do
  resource :session
  resource :registration, only: [:new, :create]
  
  namespace :admin do
    resource :settings, only: [:show, :update]
    get 'dashboard', to: 'dashboard#index'
  end

  resources :passwords, param: :token

  # Campaigns with nested Creatives
  resources :campaigns do
    member do
      post :generate
    end
    resources :creatives, only: [:index, :show, :create, :destroy] do
      member do
        post :render_image
        post :rewrite
      end
    end
  end

  # Direct route for downloading creatives
  get "creatives/:id/download", to: "creatives#download", as: :download_creative

  resources :brands

  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Landing page for logged out users, dashboard for logged in users
  root "pages#home"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
