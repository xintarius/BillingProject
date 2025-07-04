Rails.application.routes.draw do
  scope '(:locale)', locale: /en|pl/ do
  root 'landing#index'
  resource :users
  get 'landing', to: 'landing#index'
  devise_for :users, skip: [:registrations, :passwords]

  get 'dashboard', to: 'dashboard#dashboard'

  resources :invoice, only: [:index, :new, :create, :show]

  get 'settlement', to: 'settlement#index'
  get 'users/sign_out', to: 'landing#index'
  get 'users/index', to: 'users#index'
  get 'company_properties', to: 'company_properties#index'
  get 'settings', to: 'settings#index'
  get 'exports', to: 'exports#index'

  resources :invoice_type, only: [:index, :new, :create]
  resources :invoice_vat_rate, only: [:create, :new, :index]
  resources :roles, only: [:create, :new, :index]
  resources :users, only: [:create, :new]
  get "up" => "rails/health#show", as: :rails_health_check
  end
end
