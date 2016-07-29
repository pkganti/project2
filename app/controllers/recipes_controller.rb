class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all
    # raise "hell"
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
    raise "hell"
    @f2f = HTTParty.get(url1);
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
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url,:prep_duration,quantities_attributes: [:unit, :size, :_destroy],ingredients_attributes: [:name, :category, :_destroy])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name,:category)
  end

  def quantities_params
    params.require(:quantities).permit(:unit,:size)
  end
end
