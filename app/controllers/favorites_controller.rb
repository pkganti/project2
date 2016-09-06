class FavoritesController < ApplicationController
  # displaying the recipes in the favorites for the user
  def index
      user_favorites = Favorite.where(:user_id => @current_user.id).pluck(:recipe_id)
      user_recipes = Recipe.where(:user_id => @current_user.id).pluck(:id)
      recipe_id_list = (user_favorites + user_recipes)
      fav_recipes = []
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
    # adding recipes to the favorites
    f1 = Favorite.new
    user = @current_user
    # if the recipe to be favorited is coming from api
    if JSON.parse(params[:recipe][:api_recipe])['source_url'].nil?
      id = params[:id]
      recipe = Recipe.find(id)
      added_to_fav = Favorite.where(:user_id => user.id , :recipe_id => id)
      #neded to add to fav via regular
      if (added_to_fav.empty?)
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

      respond_to do |format|
        format.json  { render :json => { :status => success } }
        format.html  {redirect_to(recipe_path(recipe))}
      end
    else
      #create the recipe and then add to fav
      # recipe_api = Recipe.create api_recipe_params
      recipe_params = JSON.parse(params[:recipe][:api_recipe])
      recipe_api = Recipe.new
      recipe_api.title = recipe_params['title']
      recipe_api.images = recipe_params['images']
      recipe_api.ratings = recipe_params['ratings']
      recipe_api.prep_duration = recipe_params['prep_duration']
      recipe_api.cook_duration = recipe_params['cook_duration']
      recipe_api.servings = recipe_params['servings']
      recipe_api.directions = recipe_params['directions']
      recipe_api.source_url = recipe_params['source_url']
      recipe_api.user_id =  @current_user.id
      # adding the ingredients to the recipe object
      if recipe_params['ingredients'].present?
        recipe_params['ingredients'].each do |i|
           ing = Ingredient.new
           ing.name = i
           ing.save
           recipe_api.ingredients << ing
        end
      end
      recipe_api.save

      user.favorites << f1
      recipe_api.favorites << f1

      # if the recipe is added to favorites from html, render html, if from mobile swiper, render JSON
      respond_to do |format|
        format.json  { render :json => recipe_api, :status => success }
        format.html  {redirect_to(recipe_path(recipe_api))}
      end
      # render :json => recipe_api ,  :status => success
    end

  end

end
