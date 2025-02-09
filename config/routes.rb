Rails.application.routes.draw do
  root 'landing#index'

  get 'landing', to: 'landing#index'
  devise_for :users

  get 'dashboard/index', to: 'dashboard#index'
  get 'invoice/index', to: 'invoice#index'
  get 'settlement/index', to: 'settlement#index'
  # devise_scope :users do
  #
  #   delete 'login', to: 'devise/sessions#destroy', as: :destroy_user_session
  # end
  get 'users/sign_out', to: 'landing#index'

  get "up" => "rails/health#show", as: :rails_health_check
end
