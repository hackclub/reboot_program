Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Frontend pages
  root "pages#home"
  get "signin", to: "pages#signin", as: :signin
  get "projects", to: "pages#projects", as: :projects
  delete "signout", to: "pages#signout", as: :signout

  # OmniAuth callbacks (OmniAuth middleware handles POST /auth/:provider)
  get "auth/:provider/callback", to: "sessions#create"
  post "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"

  # API endpoints
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/token", to: "auth#token"
      get "auth/me", to: "auth#me"

      # YSWS submissions
      post "ysws/submit", to: "ysws#submit"

      # Projects
      resources :projects do
        post :request_review, on: :member
      end

      # Admin endpoints
      namespace :admin do
        resources :users, only: [:index, :show, :update, :destroy]
        resources :shop_orders, only: [:index, :show, :update]
      end
    end
  end
end
