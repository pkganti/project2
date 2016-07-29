Rails.application.routes.draw do
  get 'pages/home'

  root :to => 'pages#home'
  resources :pages
  resources :recipes
  resources :users

  get '/login' => 'session#new'
  post '/login' => 'session#create'
  delete '/logout' => 'session#destroy'

end
