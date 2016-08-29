class RecipesController < ApplicationController

  require 'open-uri'

  def index
    if params[:recipesearch].present?
      # @recipes = Recipe.all
      @recipes = Recipe.where('title ILIKE ?', '%' + params[:recipesearch] + '%')

      f2fkey="18eb516313da0e6e327844bf73c1c8e0"
      url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      string_obj = HTTParty.get(url1)
      object_obj = JSON.parse(string_obj)
      # @searchrecipes = object_obj["recipes"] no more needed
      # raise "hell"
      @searchrecipes = []
      (object_obj["recipes"]).each do |r|
        # if(r["source_url"].include?("http://www.bbcgoodfood.com" || "http://allrecipes.com"))
        if r['source_url'] =~ /bbcgoodfood.com/ || r['source_url'] =~ /allrecipes/
          #  (r["source_url"].include?"http://allrecipes.com/") )
          @searchrecipes.push(r)
        end
      end

    else
      @recipes = Recipe.all
      @list_recipes = @recipes.sample(5)

    end
  end

  def show
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj
      if (@searchrecipe["recipe"]).present?
        if @searchrecipe["recipe"]["source_url"] =~ /bbcgoodfood/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          # @searchrecipe  = bbc_scrape(source_url,recipeObj)
          # @searchrecipe = nil
          @recipe  = Recipe.bbc_scrape(source_url,recipeObj,@current_user)
        elsif @searchrecipe["recipe"]["source_url"] =~ /allrecipes/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          # @searchrecipe  = allrecipes_scrape(source_url,recipeObj)
          # @searchrecipe = nil
          @recipe  = Recipe.allrecipes_scrape(source_url,recipeObj,@current_user)
          @quantities = ''
          @all_ratings = ''
          @recipe_avg_rating = ''
          @recipe_rating = ''
        end
        binding.pry
      else
        @recipe = Recipe.find_by( :id => params[:id])
        @quantities = Quantity.where(:recipe_id => params[:id])
        @all_ratings = Rate.where(:rateable_id => @recipe.id).pluck(:stars)
        @recipe_avg_rating = ratings_avg(@recipe.id)
        @recipe_rating = (Rate.where(:rateable_id => @recipe.id , :rater_id => @recipe.user_id)).pluck(:stars)[0]
      end

  end

  def new
    @recipe = Recipe.new

     3.times { @recipe.ingredients.build }
  end

  def bookmark

    existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id).last #where is returning an array. Using last to get into the recipe
    if existing_recipe.present?

      existing_recipe.cuisine = params.fetch(:cuisine)
      existing_recipe.category = params.fetch(:category)
      existing_recipe.save
      render json: recipe_url(existing_recipe.id),  :status => 200

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
    if @current_user.present?
      existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id)

      if existing_recipe.present?
        render json: 'alreadyExists', :status => 200

        return
      end

      @chromeUrl =  params.fetch(:url)
      if @chromeUrl =~ /bbcgoodfood\.com/
        new_id = Recipe.bbc_scrape(@chromeUrl,{},save=true,@current_user)
        # @recipe = Recipe.find_by :id => new_id
        # @recipe.cuisine = params.fetch(:)
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
    else
      render json: 'needtologin',  :status => 200

    end

  end

  def create
    prep_duration = convert_time_to_seconds((params[:recipe][:prep_duration_hour]).to_i ,(params[:recipe][:prep_duration_mins]).to_i)
    cook_duration = convert_time_to_seconds((params[:recipe][:cook_duration_hour]).to_i,(params[:recipe][:cook_duration_mins]).to_i)

    @recipe = Recipe.create recipe_params
    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
    @recipe.prep_duration = prep_duration
    @recipe.cook_duration = cook_duration
    @recipe.save

    quantities = params[:recipe][:ingredients_attributes].map { |i| i[1]["quantities"] }
    ingredients = params[:recipe][:ingredients_attributes].map { |i| i[1]["ingredients"] }
      # binding.pry
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

    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
    @recipe.update recipe_params

    redirect_to @recipe
  end

  def destroy
    recipe = Recipe.find_by(:id => params[:id])
    recipe.isActive = false
    recipe.save

    redirect_to recipes_path
  end

  private

  def recipe_params
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url)
  end

  def convert_time_to_seconds(h,m)
    hour = 60 * 60 * (h).to_i
    mins = 60 * (m).to_i

    duration = hour + mins
  end


  def ratings_avg(recipe_id)
    ratings = Rate.where(:rateable_id => recipe_id).pluck(:stars)
    # binding.pry
    if (ratings.size > 0)
      avg = (ratings.sum)/(ratings.size)
    end
  end

end
