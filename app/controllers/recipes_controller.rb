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
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
