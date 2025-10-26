Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Maintenance page
  get "maintenance", to: "maintenance#show"

  root "admin/sessions#new"

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    get "dashboard", to: "dashboard#index"

    # Routes pour les pages de test (AVANT les resources pour éviter les conflits)
    get "test/client_dropdowns", to: "test#client_dropdowns"
    get "test/debug", to: "test#debug"
    get "test/routes", to: "test#routes_test"
    get "test/routes_and_drawdown", to: "test#routes_and_drawdown_test"
    get "test/drawdown_percentage", to: "test#drawdown_percentage_test"

    resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        post :reset_password
        post :regenerate_token
        post :reset_mt5
        get :trades
        get :bots
        patch :auto_detect_bots
      end
      resources :withdrawals, only: [:destroy]
      resources :deposits, only: [:destroy]
    end
    resources :payments, only: [:index, :show, :create, :update, :destroy] do
      member do
        get :download_pdf
      end
    end
    resources :credits, only: [:index, :create, :destroy]
    resources :mt5_accounts, only: [:update]
    resources :withdrawals, only: [:destroy]
    
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
      resources :backtests, only: [:index, :new, :create, :destroy] do
        member do
          post :activate
          post :recalculate
        end
      end
      
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
    
    resources :my_trades, only: [:index]
    
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
    
    resources :trades, only: [:index, :show] do
      collection do
        get :export
      end
    end
    
    resources :withdrawals, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :deposits, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :mt5_tokens, only: [:index, :new, :create, :show, :destroy] do
      collection do
        get :show_token
      end
    end
    
    resources :trade_defenders, only: [:index] do
      collection do
        post :bulk_mark_as_admin
        post :bulk_mark_as_client
        post :mark_all_pending_as_admin
        post :mark_all_pending_as_client
      end
      member do
        post :approve_trade
        post :mark_as_client_trade
        post :recalculate_penalties_for_account
      end
    end
    
    # Maintenance management
    get "maintenance", to: "maintenance#show"
    patch "maintenance", to: "maintenance#update"
    patch "maintenance/toggle", to: "maintenance#toggle"
    
    # Test page for icons
      get "test_icons", to: "dashboard#test_icons"
      get "test_dropdowns", to: "dashboard#test_dropdowns"
      get "test_dashboard_dropdowns", to: "dashboard#test_dashboard_dropdowns"
      get "test_client_dropdowns", to: "dashboard#test_client_dropdowns"
  end

  namespace :api do
    namespace :v1 do
      post "register", to: "authentication#register"
      post "login", to: "authentication#login"
      
      post "mt5/sync", to: "mt5_data#sync"
      post "mt5/sync_complete_history", to: "mt5_data#sync_complete_history"
      
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
