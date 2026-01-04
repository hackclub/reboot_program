Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Frontend pages
  root "pages#home"
  get "signin", to: "pages#signin", as: :signin
  get "projects", to: "pages#projects", as: :projects
  post "projects", to: "pages#create_project", as: :create_project
  post "projects/:id/request_review", to: "pages#request_review", as: :request_project_review
  get "shop", to: "pages#shop", as: :shop
  post "shop/purchase", to: "pages#purchase", as: :purchase
  get "purchases", to: "pages#purchases", as: :purchases
  get "faq", to: "pages#faq", as: :faq
  delete "signout", to: "pages#signout", as: :signout

  # Admin pages
  get "admin", to: "admin#index", as: :admin
  get "admin/projects", to: "admin#projects", as: :admin_projects
  post "admin/projects/:id/approve", to: "admin#approve_project", as: :admin_approve_project
  post "admin/projects/:id/reject", to: "admin#reject_project", as: :admin_reject_project

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

      # Shop
      get "shop/items", to: "shop#items"
      post "shop/purchase", to: "shop#purchase"

      # Admin endpoints
      namespace :admin do
        resources :users, only: [:index, :show, :update, :destroy]
        resources :shop_orders, only: [:index, :show, :update]
      end
    end
  end
end
