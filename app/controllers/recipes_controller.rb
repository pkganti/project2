class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all
  end

  def show
    @recipe = Recipe.find_by(where user_id)
  end

  def new
    @recipe = Recipe.new
    2.times { @recipe.quantities.build}
  end

  def create
    @recipe = Recipe.new recipe_params
    @recipe.save
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def recipe_params
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url,:prep_duration,quantities_attributes: [:unit, :size, :_destroy])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name,:category)
  end

  def quantities_params
    params.require(:quantities).permit(:unit,:size)
  end
end
