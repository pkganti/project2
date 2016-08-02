Rails.application.routes.draw do

  root :to => 'pages#home'
  resources :pages
  resources :recipes
  get '/users/edit' => 'users#edit'
  resources :users, :except => [:edit]

  get '/extension' => 'recipes#scrape'
  get '/favorites/index' => 'favorites#index' , :as => 'favorite_index'
  get '/favorites/add/:id' => 'favorites#add' , :as => 'add_favorite'
  get '/login' => 'session#new'
  post '/login' => 'session#create'
  delete '/logout' => 'session#destroy'

end
