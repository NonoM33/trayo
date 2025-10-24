Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "admin/sessions#new"

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    get "dashboard", to: "dashboard#index"

    resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        post :reset_password
        post :regenerate_token
      end
    end
    resources :payments, only: [:index, :create, :update, :destroy]
    resources :credits, only: [:index, :create, :destroy]
    resources :mt5_accounts, only: [:update]
    
    resources :bonus_deposits, only: [:index, :new, :create], path: 'bonus' do
      member do
        post :validate_deposit
        post :reject_deposit
      end
    end
    
    resources :bonus_periods do
      member do
        post :toggle_active
      end
    end
    
    resources :bots do
      member do
        delete :remove_from_user
      end
      collection do
        post :assign_to_user
      end
    end
    
    resources :shop, only: [:index, :show] do
      member do
        post :purchase
      end
    end
    
    resources :my_bots, only: [:index, :show] do
      member do
        post :toggle_status
      end
    end
    
    resources :vps, path: 'vps' do
      member do
        post :update_status
      end
    end
    
    resources :campaigns do
      member do
        post :toggle_active
      end
    end
  end

  namespace :api do
    namespace :v1 do
      post "register", to: "authentication#register"
      post "login", to: "authentication#login"
      
      post "mt5/sync", to: "mt5_data#sync"
      
      get "accounts/balance", to: "accounts#balance"
      get "accounts/trades", to: "accounts#recent_trades"
      get "accounts/projection", to: "accounts#projection"
      
      get "bots", to: "bots#list"
      get "bots/:purchase_id/status", to: "bots#status"
      post "bots/:purchase_id/performance", to: "bots#update_performance"
      
      get "users", to: "users#index"
      get "users/me", to: "users#me"
      delete "users/:id", to: "users#destroy"
    end
  end
end
