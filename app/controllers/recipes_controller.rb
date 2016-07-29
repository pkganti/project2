class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all
  end

  def show
    @recipe = Recipe.find_by(where user_id)
  end

  def new
    @recipe = Recipe.new
    # 4.times { @recipe.ingredients.build}
    #  @recipe.quantities.build

     3.times { @recipe.ingredients.build }
  end

  def create
    @recipe = Recipe.new recipe_params
    raise "hegdl"
    @recipe.quantities.each do |f|
      f.quantity_type_id = Quantity_type.find_by_name(f.quantity_type_id).id
    end
    @recipe.save

    redirect_to recipes_path
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def recipe_params
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url,:prep_duration,quantities_attributes: [:unit, :size, :_destroy],ingredients_attributes: [:name, :category, :_destroy])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name,:category)
  end

  def quantities_params
    params.require(:quantities).permit(:unit,:size)
  end
end
