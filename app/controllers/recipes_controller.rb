class RecipesController < ApplicationController

  require 'open-uri'


  def index
    if params[:recipesearch].present?
      @recipes = Recipe.all
      f2fkey="18eb516313da0e6e327844bf73c1c8e0"
      url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      string_obj = HTTParty.get(url1)
      object_obj = JSON.parse(string_obj)
      @searchrecipes = object_obj["recipes"]

      # html = @searchrecipes[1]["f2f_url"]
      # page = Nokogiri::HTML(open(html))
    else
      @recipes = Recipe.all

    end
  end

  def show
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj
    @recipe = Recipe.find_by( :id => params[:id])
    @quantities = Quantity.where(:recipe_id => params[:id])

  end

  def new
    @recipe = Recipe.new
    # 4.times { @recipe.ingredients.build}
    #  @recipe.quantities.build

     3.times { @recipe.ingredients.build }
  end

  def scrape
    @url =  params.fetch(:url)
    render json: "false",  :status => :ok
    # head :ok

  end

  def create
    prep_duration = convert_time_to_seconds((params[:recipe][:prep_duration_hour]).to_i ,(params[:recipe][:prep_duration_mins]).to_i)
    cook_duration = convert_time_to_seconds((params[:recipe][:cook_duration_hour]).to_i,(params[:recipe][:cook_duration_mins]).to_i)

    # raise "bgjda"
    @recipe = Recipe.create recipe_params
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
    @recipe.update recipe

    redirect_to @recipe
  end

  def destroy
    @recipe = Recipe.find_by(:id => params[:id])
    @recipe.destroy

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

end
