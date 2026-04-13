Rails.application.routes.draw do
  get "home/index"
  get "menu", to: "home#menu"
  get "user_bookings", to: "home#user_bookings"
  resources :bookings, only: [:index, :show]
  get "catalog", to: "home#catalog"
  get "equipment", to: "home#equipment"
  get "venue_bookings", to: "home#venue_bookings"
  get "admin_panel", to: "home#admin_panel"

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
  get "analytics", to: "home#analytics"

  namespace :api do
    # Auth
    post "auth/register", to: "auth#register"
    post "auth/login",    to: "auth#login"
    post "auth/refresh",  to: "auth#refresh"
    get  "auth/me",       to: "auth#me"

    # Bookings
    resources :bookings, only: [ :index, :show, :create ] do
      member do
        post :cancel
        post :confirm
        post :check_in
      end
      collection do
        post :create_recurring
      end
    end

    # Venues
    resources :venues, only: [ :index, :show, :create, :update, :destroy ] do
      collection do
        get :search
      end
    end

    # Equipment
    resources :equipment, only: [ :index, :show, :create, :update, :destroy ] do
      collection do
        get :search
      end
    end

    # Analytics
    get "analytics/bookings/stats", to: "analytics#booking_stats"
    get "analytics/venues/usage",   to: "analytics#venue_usage"
    get "analytics/peak-times",     to: "analytics#peak_times"

    # Maps
    get "venues/:id/map",           to: "maps#show"

    # Admin
    get    "admin/users",              to: "admin#users",       as: :admin_users
    post   "admin/users",              to: "admin#create_user"
    get    "admin/users/:id",          to: "admin#show_user",   as: :admin_user
    put    "admin/users/:id",          to: "admin#update_user"
    patch  "admin/users/:id",          to: "admin#update_user"
    post   "admin/users/:id/suspend",  to: "admin#suspend_user", as: :admin_user_suspend
    delete "admin/users/:id",          to: "admin#delete_user"
    post   "admin/bookings/:id/force_cancel", to: "admin#force_cancel", as: :admin_booking_force_cancel

    # AI
    post "ai/ask",               to: "ai#ask"
    post "ai/recommend-venues",  to: "ai#recommend_venues"
    post "ai/check-conflicts",   to: "ai#check_conflicts"
    get  "ai/status",            to: "ai#status"
  end
end
