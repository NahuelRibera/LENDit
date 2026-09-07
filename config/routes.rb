Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resource :session, only: [:new, :create, :destroy]
  resource :registration, only: [:new, :create]
  resource :password_reset, only: [:new, :create, :edit, :update]

  namespace :account do
    resource :profile, only: [:edit, :update]
    resources :listings, only: [:index]
    resources :lends, only: [:index]
    resources :borrows, only: [:index]
  end

  resources :users, only: [:show]

  resources :categories, only: [:index, :show], param: :slug

  resources :listings, only: [:index, :new, :create, :show, :edit, :update] do
    resource :status, only: [:update], controller: "listings/statuses"
    resources :images, only: [:create, :update, :destroy], controller: "listing_images"
    resources :rentals, only: [:create]
    resource :conversation, only: [:create], controller: "listing_conversations"
  end

  resources :rentals, only: [:show] do
    resource :acceptance, only: [:create], controller: "rentals/acceptances"
    resource :decline, only: [:create], controller: "rentals/declines"
    resource :cancellation, only: [:create], controller: "rentals/cancellations"
  end

  resources :conversations, only: [:index, :show] do
    resources :messages, only: [:create]
  end

  resources :notifications, only: [:index] do
    resource :read, only: [:create], controller: "notifications/reads"
  end
  resource :notifications_read_all, only: [:create], controller: "notifications/read_alls"
end
