class RecipesController < ApplicationController

  def index
    @recipes = Recipe.all
  end

  def show
    @recipe = Recipe.find_by(where id => params[:id])
    @quantity = Quantity.where(recipe_id => params[:id])
  end

  def new
    @recipe = Recipe.new
    # 4.times { @recipe.ingredients.build}
    #  @recipe.quantities.build

     3.times { @recipe.ingredients.build }
  end

  def create
    @recipe = Recipe.new params[:recipe]  params[:recipe][:ingredients_attributes]

    # @recipe.quantities.each do |f|
    #   f.quantity_type_id = Quantity_type.find_by_name(f.quantity_type_id).id
    # end
#     params[:recipe][:ingredients_attributes].values.each do |ingredient|
#         ingredient[:type_id].values.each do |a|
#           a[:type_id]
#         end
# end if params[:recipe] and params[:recipe][:ingredients_attributes]
    abc= params[:recipe][:ingredients_attributes].values.each do |ingredient|
        ingredient[:type_id].values.each do |a|
          a[:type_id]
        end
end if params[:recipe] and params[:recipe][:ingredients_attributes]
raise "hegdl"

    @recipe.save

    redirect_to recipes_path
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
    params.require(:recipe).permit(:title,:directions,:cook_duration,:ratings,:category,:cuisine,:images,:level,:servings,:source_url,:prep_duration,quantities: [:unit, :size, :_destroy],ingredients: [:name, :category, :_destroy])
  end
end
