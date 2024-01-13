Rails.application.routes.draw do
  resources :ticket_comments

  #devise_for :users

  devise_for :users, controllers: { sessions: 'users/sessions' }

  resources :tickets do 
    put "bcc", :action => 'bcc'
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/search/show/:search_params/:page', :controller => :search, :action => 'show'
  post '/search/:search_params/:page', :controller => :search, :action => 'create'
  #
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root "tickets#index"
end
