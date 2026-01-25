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
  post "shop/suggest_item", to: "pages#suggest_item", as: :suggest_item
  get "purchases", to: "pages#purchases", as: :purchases
  get "faq", to: "pages#faq", as: :faq
  delete "signout", to: "pages#signout", as: :signout

  # Dev-only helper to log in without OAuth
  if Rails.env.development?
    get "dev_login", to: "pages#dev_login", as: :dev_login
  end

  # Admin pages
  get "admin", to: "admin#index", as: :admin
  get "admin/projects", to: "admin#projects", as: :admin_projects
  get "admin/projects/:id", to: "admin#project_detail", as: :admin_project
  get "admin/users", to: "admin#users", as: :admin_users
  get "admin/shop", to: "admin#shop", as: :admin_shop
  get "admin/jobs", to: "admin#jobs", as: :admin_jobs
  get "admin/stats", to: "admin#stats", as: :admin_stats
  post "admin/jobs/:id/retry", to: "admin#retry_job", as: :admin_retry_job
  delete "admin/jobs/:id", to: "admin#discard_job", as: :admin_discard_job
  post "admin/jobs/run_airtable_sync", to: "admin#run_airtable_sync", as: :admin_run_airtable_sync

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

      # Uploads
      post "uploads", to: "uploads#create"

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
        resources :item_suggestions, only: [ :update ]
        resources :projects, only: [ :destroy ] do
          member do
            post :approve
            post :reject
          end
          resources :journal_entries, only: [ :index, :show ]
        end
      end
    end
  end
end
