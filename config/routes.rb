# encoding: UTF-8
# frozen_string_literal: true

# Explicitly require "lib/peatio.rb".
# You may be surprised why this line also sits in config/application.rb.
# The same line sits in config/application.rb to allows early access to lib/peatio.rb.
# We duplicate line in config/routes.rb since routes.rb is reloaded when code is changed.
# The implementation of ActiveSupport's require_dependency makes sense to use it only in reloadable files.
# That's why it is here.
require_dependency 'peatio'

Dir['app/models/deposits/**/*.rb'].each { |x| require_dependency x.split('/')[2..-1].join('/') }
Dir['app/models/withdraws/**/*.rb'].each { |x| require_dependency x.split('/')[2..-1].join('/') }

class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Peatio::Application.routes.draw do

  root 'welcome#index'

  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure', :as => :failure
  match '/auth/:provider/callback' => 'sessions#create', via: %i[get post]

  scope module: :private do
    resources :settings, only: [:index]

    namespace :settings do  
      get 'edit_profile' => 'edit_profile#index'
#      get 'phones' => 'edit_profile#step1'
#      get 'profiles' => 'edit_profile#step2'
#      get 'documents' => 'edit_profile#step3'
#      get 'next_step' => 'edit_profile#next_step'
#      get 'previous_step' => 'edit_profile#previous_step'
      post 'edit_profile/send_code', to: 'edit_profile#send_code'
#      post 'edit_profile/phones_verification', to: 'edit_profile#verify_phone'
      post 'edit_profile/submit_edit_profile_form', to: 'edit_profile#submit_edit_profile_form'
#      get 'payee_list' => 'settings#payee_list'
      get 'security' => 'security#index'
      namespace :security do  
        get 'change_password' => 'change_password#index'
        post 'change_password', to: 'change_password#submit_change_password_form'
      end
#      get 'security/enable_2fa' => 'security#enable_2fa'
#      get 'security/disable_2fa' => 'security#disable_2fa'
#      get 'notifications' => 'settings#notifications'
#      get 'mobile' => 'settings#mobile'
#      resources :profiles,  only: %i[new create], controller: 'edit_profile'
#      resources :documents, only: %i[new create], controller: 'edit_profile'
    end      

    resources :withdraw_destinations, only: %i[ create update ]

    resources :funds, only: [:index] do
      collection do
        post :gen_address
      end
    end

    resources 'deposits/:currency', controller: 'deposits', as: 'deposit', only: %i[ destroy ] do
      collection { post 'gen_address' }
    end

    resources 'withdraws/:currency', controller: 'withdraws', as: 'withdraw', only: %i[ create destroy ]

    get '/history/orders' => 'history#orders', as: :order_history
    get '/history/trades' => 'history#trades', as: :trade_history
    get '/history/account' => 'history#account', as: :account_history

    resources :markets, only: [:show], constraints: MarketConstraint do
      resources :orders, only: %i[ index destroy ] do
        collection do
          post :clear
        end
      end
      resources :order_bids, only: [:create] do
        collection do
          post :clear
        end
      end
      resources :order_asks, only: [:create] do
        collection do
          post :clear
        end
      end
    end
  end

  get 'health/alive', to: 'public/health#alive'
  get 'health/ready', to: 'public/health#ready'

  get 'trading/:market_id', to: BlackHoleRouter.new, as: :trading

  draw :admin

  get '/swagger', to: 'swagger#index'

  mount APIv2::Mount => APIv2::Mount::PREFIX
  mount ManagementAPIv1::Mount => ManagementAPIv1::Mount::PREFIX
end
