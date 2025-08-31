Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"
  resources :time_off_requests, only: %i[new index]
  namespace :manager do
    root "dashboard#index"
  end

  # API
  namespace :api do
    namespace :v1 do
      resources :time_off_requests, only: %i[index show create update] do
        collection do
          get :manager_dashboard
        end
        member do
          patch :approve
          patch :deny
        end
      end

      resources :users, only: %i[index show] do
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
