Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  scope '(:locale)', locale: /en|pl/ do
    root 'landing#index'
    resource :users
    get 'landing', to: 'landing#index'
    devise_for :users, skip: [:registrations, :passwords]

    get 'dashboard', to: 'dashboard#dashboard'

    resources :invoice, only: [:index, :new, :create, :show]

    get 'statistics', to: 'statistics#index'
    get 'week_settlements', to: 'settlement#week_settlements'
    get 'month_settlements', to: 'settlement#month_settlements'
    get 'users/sign_out', to: 'landing#index'
    get 'users/index', to: 'users#index'
    get 'company_properties', to: 'company_properties#index'
    get 'settings', to: 'settings#index'
    post 'generate_month_settlement', to: 'settlement#generate_month_settlement'


    resources :receipts, only: [:index]
    resources :exports, only: [:index, :show] do
      member do
        get 'download', to: 'exports#download'
      end
    end
    resources :invoice_type, only: [:index, :new, :create]
    resources :invoice_vat_rate, only: [:create, :new, :index]
    resources :roles, only: [:create, :new, :index]
    resources :users, only: [:create, :new]
    get "up" => "rails/health#show", as: :rails_health_check

    namespace :api do
      namespace :v1 do
        get 'courier_billings/:id', to: 'courier_billings#earnings'
      end
    end
  end
end
