Rails.application.routes.draw do

  root :to => 'pages#home'
  resources :pages
  resources :recipes
  get '/users/edit' => 'users#edit'
  resources :users, :except => [:edit]

  get '/extension' => 'recipes#scrape'
  get '/extensionbookmark' => 'recipes#bookmark'

  get '/login' => 'session#new'
  post '/login' => 'session#create'
  delete '/logout' => 'session#destroy'

end
