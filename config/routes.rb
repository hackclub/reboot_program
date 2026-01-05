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
  get "admin/projects/:id", to: "admin#project_detail", as: :admin_project
  get "admin/users", to: "admin#users", as: :admin_users
  get "admin/shop", to: "admin#shop", as: :admin_shop

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
        member do
          post :request_review
          post :sync_hackatime
        end
        resources :journal_entries, only: [ :index, :show, :create, :update, :destroy ]
      end

      # Hackatime
      get "hackatime/projects", to: "hackatime#projects"

      # Shop
      get "shop/items", to: "shop#items"
      post "shop/purchase", to: "shop#purchase"

      # Admin endpoints
      namespace :admin do
        resources :users, only: [ :index, :show, :update, :destroy ]
        resources :shop_orders, only: [ :index, :show, :update ]
        resources :shop_items, only: [ :index, :show, :create, :update, :destroy ]
        resources :projects, only: [] do
          member do
            post :approve
            post :reject
          end
        end
      end
    end
  end
end
