Rails.application.routes.draw do
  get "home/index"

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

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
    get    "admin/users",              to: "admin#users"
    post   "admin/users/:id/suspend",  to: "admin#suspend_user"
    delete "admin/users/:id",          to: "admin#delete_user"
    post   "admin/bookings/:id/force_cancel", to: "admin#force_cancel"

    # AI
    post "ai/ask",               to: "ai#ask"
    post "ai/recommend-venues",  to: "ai#recommend_venues"
    post "ai/check-conflicts",   to: "ai#check_conflicts"
    get  "ai/status",            to: "ai#status"
  end
end