Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  
  mount ActionCable.server => "/cable"
  get "up" => "rails/health#show", as: :rails_health_check

  # API Documentation
  get "api-docs", to: "api_documentation#show", as: :api_documentation
  get "api-docs/swagger.yaml", to: "swagger_yaml#show", as: :swagger_yaml

  # Maintenance page
  get "maintenance", to: "maintenance#show"

  # Webhooks
  post "webhooks/sms", to: "webhooks/sms#receive"

  root "admin/sessions#new"
  
  get "join", to: "onboarding#landing"
  get "join/:code", to: "onboarding#show", as: :onboarding
  get "join/:code/step/:step", to: "onboarding#step", as: :onboarding_step
  post "join/:code/next", to: "onboarding#next_step", as: :onboarding_next_step
  get "join/:code/complete", to: "onboarding#complete", as: :onboarding_complete

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    get "dashboard", to: "dashboard#index"
    get "dashboard/monitoring_status", to: "dashboard#monitoring_status"

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
        post :send_commission_sms
        get :sms_preview
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
    resources :invoices, only: [:index, :show] do
      resources :payments, only: [:create], controller: "invoice_payments"
    end
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

    resources :sms_logs, only: [:index]
    
    resources :support_tickets, only: [:index, :show, :update, :destroy] do
      member do
        post :mark_as_read
      end
    end
    
    resources :invitations, only: [:index, :new, :create, :show, :destroy]
    
    resources :trades, only: [:index, :show] do
      collection do
        get :export
      end
    end
    
    resources :withdrawals, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      collection do
        post :bulk_destroy
      end
    end
    resources :deposits, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      collection do
        post :bulk_destroy
      end
    end
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
    
    # Database backups
    resources :backups, only: [:index, :show, :create, :destroy] do
      member do
        post :restore
        get :download
      end
      collection do
        post :upload
      end
    end
    
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

    namespace :v2 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"
      get "auth/me", to: "auth#me"

      resources :accounts, only: [:index, :show] do
        member do
          get :balance
          get :trades
          get :projection
          get :stats
        end
      end

      resources :trades, only: [:index, :show] do
        collection do
          get :stats
          get :export
        end
      end

      resources :bots, only: [:index, :show]
      get "my_bots", to: "bots#my_bots"
      
      resources :bot_purchases, only: [:index, :show, :create] do
        member do
          get :status
          post :start
          post :stop
          post :performance
        end
      end

      resources :vps, only: [:index, :show]

      resources :payments, only: [:index, :show, :create] do
        collection do
          get :balance_due
        end
      end

      resources :credits, only: [:index, :show]

      namespace :stats do
        get :dashboard
        get :profits
        get :trades
      end

      namespace :users do
        get :me
        patch :me, to: "users#update"
        patch "me/password", to: "users#update_password"
        delete :me, to: "users#destroy"
      end

      get "events", to: "events#index"
    end
  end
end
