class FavoritesController < ApplicationController
  def index
      user_favorites = Favorite.where(:user_id => @current_user.id).pluck(:recipe_id)
      user_recipes = Recipe.where(:user_id => @current_user.id).pluck(:id)
      recipe_id_list = (user_favorites + user_recipes)
      fav_recipes = []
      # params[:recipesearch] = 'potato'
      search_fav_recipes = []
      recipe_id_list.each do |id|
        fav_recipes.push(Recipe.find(id))
      end
      if params[:recipesearch].present?
        fav_recipes.each do |r|
          search_fav_recipes.push(r) if r['title'] =~ /#{params[:recipesearch]}/i
        end
      end
      if search_fav_recipes.present?
        @recipes = search_fav_recipes
      else
        @recipes = fav_recipes
      end
  end

end
