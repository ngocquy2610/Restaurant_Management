Rails.application.routes.draw do
  require "sidekiq/web"
  require "sidekiq/cron/web"
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  namespace :inventory do
    root "dashboards#index"

    resources :reports
    resources :stock_transactions, only: %i[index show]
    resources :restock_tasks, only: %i[index show] do
      member do
        get   :refill
        patch :complete
      end
    end
    resources :low_stock_requests, only: %i[index show] do
      member { patch :review }
    end
    resources :waste_reports, only: %i[index show] do
      member { patch :verify }
    end

    resources :stock_adjustments, only: %i[new create]
  end

  namespace :kitchen do
    root "dashboards#index"

    resources :low_stock_requests, only: %i[index show new create]
    resources :waste_reports, only: %i[index show new create]
  end

  resources :reviews, only: %i[ index show new create edit update destroy ] do
    collection do
      get :restaurant
    end
  end

  resources :order_items, only: [:create, :destroy] do
    member do
      patch :update_status
    end
  end

  resources :orders do
    member do
      patch :update_status
    end

    resources :payments, only: [:create] do
      member do
        get :bill, to: "bills#show"
        get :success
        patch :confirm
      end
    end
  end

  resources :reservations do
    resources :preorders, only: %i[ new create ]
    member do
      patch :update_status
    end
  end
  resources :preorders, only: %i[ show index destroy ] do
    member do
      patch :release
    end
  end

  resources :notifications do
    collection do
      patch :mark_all_read
    end
  end
  resources :promotions
  resources :menus, only: [:index, :show]
  resources :categories

  resources :foods do
    resources :recipe_items, only: [:new, :edit, :create, :update, :destroy], shallow: true
  end

  resources :food_variants
  resources :recipe_items, only: [:new, :edit, :create, :update, :destroy]

  resources :ingredients do
    member do
      patch :deactivate
      patch :reactivate
    end
  end

  resources :tables
  resources :table_types
  # Public read-only floor-map viewer (single area at a time). Editing/drag-drop
  # (create/update/destroy) will be reintroduced in a later phase.
  # resources :tables, only: [:new, :create, :edit, :update, :destroy, :index, :show]
  resources :areas, only: [:new, :create, :edit, :update, :destroy]
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
  get "our-story", to: "home#our_story", as: :our_story
  get "contact-us", to: "home#contact_us", as: :contact_us
  get "careers", to: "home#careers", as: :careers
  get "privacy-policy", to: "home#privacy_policy", as: :privacy_policy
  get "terms-of-service", to: "home#terms_of_service", as: :terms_of_service

  get 'admin/users', to: "users#index"
  get 'admin/dashboards', to: "dashboards#index"
# Admin/receptionist reservation review and confirmation (separate from the
  # public /reservations booking page).
  namespace :admin do
    resources :reservations, only: [:index] do
      member do
        patch :update_status
        patch :assign_table
        patch :change_table
      end
    end

    resources :customer_queues, only: [:index, :create, :destroy] do
      member do
        patch :cancel
        patch :seat
      end
    end

    resources :kitchen_queues, only: [:index, :show] do
      patch "items/:id/update_status",
            to: "kitchen_queues#update_status",
            as: :update_item_status
    end
  end

  resources :users, only: [:show, :edit, :update, :destroy]
end
