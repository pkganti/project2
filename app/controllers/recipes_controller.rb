class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all
    # raise "hell"
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"

    @f2f = HTTParty.get(url1);

  end

  def show
    @recipe = Recipe.find_by( :id => params[:id])
    @quantities = Quantity.where(:recipe_id => params[:id])
  end

  def new
    @recipe = Recipe.new
    # 4.times { @recipe.ingredients.build}
    #  @recipe.quantities.build

     3.times { @recipe.ingredients.build }
  end

  def create

    @recipe = Recipe.create recipe_params
    quantities = params[:recipe][:ingredients_attributes].map { |i| p i[1]["quantities"] }
    ingredients = params[:recipe][:ingredients_attributes].map { |i| p i[1]["ingredients"] }
      binding.pry
    ingredients.each_with_index do |i, index|
      ingredient = Ingredient.create(i.to_hash)
      @recipe.ingredients << ingredient
      # quantity = Quantity.create( quantities[index].to_hash )
      p quantities[index]
      # ingredient.quantities << quantity
    end
    ingredients.each_with_index do |i, index|
      ingredient = Ingredient.create(i.to_hash)
      @recipe.ingredients << ingredient
      # quantity = Quantity.create( quantities[index].to_hash )
      p quantities[index][:unit]
      # ingredient.quantities << quantity
    end

    @recipe.save

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
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url,:prep_duration)
  end
end
