Rails.application.routes.draw do

  post '/rate' => 'rater#create', :as => 'rate'
  root :to => 'pages#home'
  resources :pages
  resources :recipes
  get '/users/edit' => 'users#edit'
  resources :users, :except => [:edit]

  get '/extension' => 'recipes#scrape'
  get '/extensionbookmark' => 'recipes#bookmark'

  get '/favorites/index' => 'favorites#index' , :as => 'favorite_index'
  get '/favorites/add/:id' => 'favorites#add' , :as => 'add_favorite'
  post '/favorites/add/:id' => 'favorites#add' , :as => 'add_favorite_api'

  get '/login' => 'session#new'
  post '/login' => 'session#create'
  delete '/logout' => 'session#destroy'

end
