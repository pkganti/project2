class RecipesController < ApplicationController

  def index
    if params[:recipesearch].present?
      @recipes = Recipe.all
      f2fkey="18eb516313da0e6e327844bf73c1c8e0"
      url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      string_obj = HTTParty.get(url1)
      object_obj = JSON.parse(string_obj)
      @searchrecipes = object_obj["recipes"]
      # Commenting this part as unable to process https request
      # rId = object_obj["recipes"].first['recipe_id']
      # url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      # url2 = "https://community-food2fork.p.mashape.com/get?key=#{f2fkey}&rId=#{rId}"
      # # binding.pry
      # string_obj2 = HTTParty.get(url2)
      # object_obj2 = JSON.parse(string_obj2)

    else
      @recipes = Recipe.all
      # raise "hell"
    end
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
