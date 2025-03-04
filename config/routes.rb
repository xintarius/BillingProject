Rails.application.routes.draw do
  root 'landing#index'
  resource :users
  get 'landing', to: 'landing#index'
  devise_for :users

  get 'dashboard', to: 'dashboard#dashboard'
  get 'invoice', to: 'invoice#index'
  get 'settlement', to: 'settlement#index'
  get 'users/sign_out', to: 'landing#index'
  get 'users/index', to: 'users#index'
  get 'company_properties', to: 'company_properties#index'
  resources :users, only: [:create, :new]
  get "up" => "rails/health#show", as: :rails_health_check
end
