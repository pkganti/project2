class RecipesController < ApplicationController

  require 'open-uri'


  def index
    if params[:recipesearch].present?
      @recipes = Recipe.all
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
      # raise "hell"
      # binding.pry
      # Commenting this part as unable to process https request
      # rId = object_obj["recipes"].first['recipe_id']
      # url1 = "http://food2fork.com/api/search?key=#{f2fkey}&q=#{params[:recipesearch]}"
      # url2 = "https://community-food2fork.p.mashape.com/get?key=#{f2fkey}&rId=#{rId}"
      # # binding.pry
      # string_obj2 = HTTParty.get(url2)
      # object_obj2 = JSON.parse(string_obj2)

      # html = @searchrecipes[1]["f2f_url"]
      # page = Nokogiri::HTML(open(html))
    else
      @recipes = Recipe.all

    end
  end

  def show
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    # binding.pry
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj

    if @searchrecipe["recipe"]["source_url"] =~ /bbcgoodfood/
      source_url = @searchrecipe["recipe"]["source_url"]
      recipeObj = @searchrecipe["recipe"]
      # binding.pry
      @searchrecipe  = bbc_scrape(source_url,recipeObj)
    end
    if @searchrecipe["recipe"]["source_url"] =~ /allrecipes/
      source_url = @searchrecipe["recipe"]["source_url"]
      recipeObj = @searchrecipe["recipe"]
      @searchrecipe  = allrecipes_scrape(source_url,recipeObj)
    end



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

  def bbc_scrape(url,r)
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']

    prep_time= doc.css('.recipe-details__cooking-time-prep > span').text
    if ((prep_time.split(/hrs?/)).size > 1)
     preparation_time = prep_time.split(/hrs?/)
    else
     preparation_time.push(prep_time)
    end
    cook_time = doc.css('.recipe-details__cooking-time-cook > span').text
    if ((cook_time.split(/hrs?/)).size > 1)
     cooking_time = cook_time.split(/hrs?/)
    else
     cooking_time.push(cook_time)
    end
    level = doc.css('.recipe-details__item--skill-level').css('span').text.strip
    servings = doc.css('.recipe-details__item--servings').css('span').text.strip
    directions = []
    doc.css('#recipe-method').css('ol').each do |step|
     directions.push(step.css('li').text.strip.gsub("\n", '<br>'))

    end
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions})

  end

  def allrecipes_scrape(url,r)

    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    # raise "hell"
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']

    prep_time= doc.css("time[itemprop='prepTime']").text
    cook_time = doc.css("time[itemprop='cookTime']").text

    servings = doc.css("span[ng-bind='adjustedServings']").text.strip
    directions = []
    doc.css('#recipe-method').css('ol').each do |step|
     directions.push(step.css('li').text.strip.gsub("\n", '<br>'))

    end
    r.merge!( {'ratings' => ratings , 'prep_duration' => prep_time ,'cook_duration' => cook_time , 'servings' => servings , 'directions' => directions})

  end

end
