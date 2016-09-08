class RecipesController < ApplicationController
  #requiring open-uri for nokogiri
  require 'open-uri'

  # method to display the recipes using search term or display in general
  def index
    # check if the user has searched for a recipe
    if params[:recipesearch].present?
      @recipes = Recipe.where('title ILIKE ?', '%' + params[:recipesearch] + '%')

      f2fkey="18eb516313da0e6e327844bf73c1c8e0"
      url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      string_obj = HTTParty.get(url1)
      object_obj = JSON.parse(string_obj)
      @searchrecipes = []
      (object_obj["recipes"]).each do |r|
        if r['source_url'] =~ /bbcgoodfood.com/ || r['source_url'] =~ /allrecipes/
          @searchrecipes.push(r)
        end
      end
      # display 5 the recipes in random if no search term is given
    else
      @recipes = Recipe.all
      @list_recipes = @recipes.sample(5)

    end
  end

  def show
    #Fetching recipe from api search
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj
      if (@searchrecipe["recipe"]).present?
        # checking if the recipe is fetched from bbc good food
        if @searchrecipe["recipe"]["source_url"] =~ /bbcgoodfood/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          # calling bbc_scrape to fetch recipe detials from model
          @recipe  = Recipe.bbc_scrape(source_url,recipeObj,@current_user)
        # checking if the recipe is fetched from all recipes
        elsif @searchrecipe["recipe"]["source_url"] =~ /allrecipes/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          # calling allrecipes_scrape to fetch recipe detials from model
          @recipe  = Recipe.allrecipes_scrape(source_url,recipeObj,@current_user)
          @quantities = ''
          @all_ratings = ''
          @recipe_avg_rating = ''
          @recipe_rating = ''
        end
      else
        # fetching recipe from the database
        @recipe = Recipe.find_by( :id => params[:id])
        @quantities = Quantity.where(:recipe_id => params[:id])
        @all_ratings = Rate.where(:rateable_id => @recipe.id).pluck(:stars)
        @recipe_avg_rating = ratings_avg(@recipe.id)
        @recipe_rating = (Rate.where(:rateable_id => @recipe.id , :rater_id => @recipe.user_id)).pluck(:stars)[0]
      end

  end

  def new
    @recipe = Recipe.new
    # giving options for 3 ingredients
    3.times { @recipe.ingredients.build }
  end

  # method to bookmark a recipe, being called from extension.js
  def bookmark
     #where is returning an array. Using last to get into the recipe
    existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id).last
    # if that recipe is already present in the database
    if existing_recipe.present?
      existing_recipe.cuisine = params.fetch(:cuisine)
      existing_recipe.category = params.fetch(:category)
      existing_recipe.save
      render json: recipe_url(existing_recipe.id),  :status => 200
    # if that recipe is not present in the database
    else
      recipe = Recipe.new
      recipe.source_url = params.fetch(:url)
      recipe.title = params.fetch(:title)
      recipe.cuisine = params.fetch(:cuisine)
      recipe.category = params.fetch(:category)
      recipe.prep_duration = convert_time_to_seconds(params.fetch(:prep_duration_hour), params.fetch(:prep_duration_mins))
      recipe.cook_duration = convert_time_to_seconds(params.fetch(:cook_duration_hour), params.fetch(:cook_duration_mins))
      recipe.user = @current_user
      recipe.images = params.fetch(:images)
      recipe.save
      render json: recipe_url(recipe.id),  :status => 200
    end
  end

  def scrape
    # checking if user is present, then scrape it,
    if @current_user.present?
      existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id)
      #else take the user to the palate show recipes page
      if existing_recipe.present?
        render json: 'alreadyExists', :status => 200

        return
      end
      # calling the scrape methods for models for the relevant sites
      # used arguments 'url','object', 'option for save' , 'current_user details'
      @chromeUrl =  params.fetch(:url)
      if @chromeUrl =~ /bbcgoodfood\.com/
        new_id = Recipe.bbc_scrape(@chromeUrl,{},save=true,@current_user)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /taste\.com\.au/
        new_id = Recipe.taste_scrape(@chromeUrl.gsub(' ','+'),{},save=true,@current_user)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /foodnetwork\.com/
        new_id = Recipe.foodNetwork_scrape(@chromeUrl,{},save=true,@current_user)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /allrecipes\.com/
        new_id = Recipe.allrecipes_scrape(@chromeUrl,{}, save=true,@current_user)
        status = recipe_url(new_id)
      else
        status = 'notok'
      end

      render json: status,  :status => 200
    #  else take the user to the palate login page
    else
      render json: 'needtologin',  :status => 200

    end

  end

  def create
    # convert duration into mins
    prep_duration = convert_time_to_seconds((params[:recipe][:prep_duration_hour]).to_i ,(params[:recipe][:prep_duration_mins]).to_i)
    cook_duration = convert_time_to_seconds((params[:recipe][:cook_duration_hour]).to_i,(params[:recipe][:cook_duration_mins]).to_i)
    # create recipe object
    @recipe = Recipe.create recipe_params
    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
    @recipe.prep_duration = prep_duration
    @recipe.cook_duration = cook_duration
    @recipe.save
    # creating the ingredients
    quantities = params[:recipe][:ingredients_attributes].map { |i| i[1]["quantities"] }
    ingredients = params[:recipe][:ingredients_attributes].map { |i| i[1]["ingredients"] }
    # creating the quantity
    ingredients.each_with_index do |i, index|
      quantity = Quantity.new( quantities[index].to_hash )
      quantity.recipe_id = @recipe.id
      ingredient = Ingredient.create( i.to_hash )
      quantity.ingredient_id = ingredient.id
      quantity.save
    end

    redirect_to @recipe
  end

  def edit
    @recipe = Recipe.find_by :id => params[:id]
  end

  def update
    @recipe = Recipe.find_by :id => params[:id]
    # check if the images for recipes has been updated
    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
    # saving the recipe with updated params
    @recipe.update recipe_params

    redirect_to @recipe
  end

  def destroy
    # Setting the flag to isActive as false if a user tries to delete a recipe
    recipe = Recipe.find_by(:id => params[:id])
    if recipe.user = @current_user
      recipe.isActive = false
      recipe.save
    end

    redirect_to recipes_path
  end

  private
 # whitelisting the params
  def recipe_params
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url)
  end

# method to convert the time into seconds
  def convert_time_to_seconds(h,m)
    hour = 60 * 60 * (h).to_i
    mins = 60 * (m).to_i

    duration = hour + mins
  end


  def ratings_avg(recipe_id)
    ratings = Rate.where(:rateable_id => recipe_id).pluck(:stars)

    if (ratings.size > 0)
      avg = (ratings.sum)/(ratings.size)
    end
  end

end
