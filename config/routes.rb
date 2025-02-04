Rails.application.routes.draw do
  root 'dashboard#index'
  get 'landing', to: 'landing#home'
  devise_for :users

  get 'dashboard/index', to: 'dashboard#index'
  get "up" => "rails/health#show", as: :rails_health_check
end
