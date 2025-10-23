Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "admin/sessions#new"

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        post :reset_password
        post :regenerate_token
      end
    end
    resources :payments, only: [:index, :create, :update, :destroy]
    resources :credits, only: [:index, :create, :destroy]
    resources :mt5_accounts, only: [:update]
  end

  namespace :api do
    namespace :v1 do
      post "register", to: "authentication#register"
      post "login", to: "authentication#login"
      
      post "mt5/sync", to: "mt5_data#sync"
      
      get "accounts/balance", to: "accounts#balance"
      get "accounts/trades", to: "accounts#recent_trades"
      get "accounts/projection", to: "accounts#projection"
      
      get "users", to: "users#index"
      get "users/me", to: "users#me"
      delete "users/:id", to: "users#destroy"
    end
  end
end
