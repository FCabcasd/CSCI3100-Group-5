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
    resources :bookings, only: [:index, :show, :create] do
      member do
        post :cancel
        post :confirm
      end
      collection do
        post :create_recurring
      end
    end

    # Venues
    resources :venues, only: [:index, :show, :create, :update, :destroy]

    # Equipment
    resources :equipment, only: [:index, :show, :create, :update, :destroy]

    # Admin
    get    "admin/users",              to: "admin#users"
    post   "admin/users/:id/suspend",  to: "admin#suspend_user"
    delete "admin/users/:id",          to: "admin#delete_user"

    # AI
    post "ai/ask",               to: "ai#ask"
    post "ai/recommend-venues",  to: "ai#recommend_venues"
    post "ai/check-conflicts",   to: "ai#check_conflicts"
    get  "ai/status",            to: "ai#status"
  end
end
