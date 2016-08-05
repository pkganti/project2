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

  def add
    f1 = Favorite.new
    #  binding.pry
    user = @current_user
    id = params[:id]
    recipe = Recipe.find(id)
    # raise 'help'

    added_to_fav = Favorite.where(:user_id => user.id , :recipe_id => id)
    added_by_me = Recipe.where(:user_id => user.id, :id => id)

    if (added_to_fav.empty? && added_by_me.empty?)
      user.favorites << f1
      recipe.favorites << f1

      f1.save
      if (f1.save)
        #flash[:notice] = "Successfully bookmarked your recipe !!"
        success = true
      end

    else
    #   flash[:notice] = "Already bookmarked !!"
      success = false
    end
    render :json => { :status => success }
    # redirect_to :back

  end

end
