Rails.application.routes.draw do
  resources :users
  # get "path", to: "controller#action"

  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  devise_for :users,
    controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations',
      passwords: 'users/passwords'
    },
    path: '',
    path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'register', password: 'forgot-password' }

  authenticated :user do
    root to: 'home#index', as: :authenticated_root
  end
  root to: 'home#index'
  
  resources :users, only: [:show]
end
