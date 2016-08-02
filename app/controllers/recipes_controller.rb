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

    end
  end

  def show
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    # binding.pry
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj

  #   @s = 'ABCD'
  #   foodnetwork_url = 'http://www.foodnetwork.com/recipes/town-housereg-flatbread-crispsreg-crusted-mahi-mahi-with-curry-dill-aioli-recipe.print.html'
  #   if @s.eql?'ABCD'
  #   @s = foodNetwork_scrape(foodnetwork_url,@s)
  # end
  #   # taste_url = "http://www.taste.com.au/recipes/20860/spaghetti+with+garlic+butter+bacon+and+prawns?ref=collections,pasta-recipes"


    # if taste_url
    #   recipeObj = {}
    #   @searchrecipe = taste_scrape(taste_url,recipeObj)
    #   # binding.pry

    if @searchrecipe["recipe"]["source_url"] =~ /bbcgoodfood/
      source_url = @searchrecipe["recipe"]["source_url"]
      recipeObj = @searchrecipe["recipe"]
      # binding.pry
      @searchrecipe  = bbc_scrape(source_url,recipeObj)

    elsif @searchrecipe["recipe"]["source_url"] =~ /allrecipes/
      source_url = @searchrecipe["recipe"]["source_url"]
      recipeObj = @searchrecipe["recipe"]
      @searchrecipe  = allrecipes_scrape(source_url,recipeObj)
    end
  # end

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
    @chromeUrl =  params.fetch(:url)
    render json: @chromeUrl,  :status => :ok

    if @chromeUrl =~ /bbcgoodfood/
      bbc_scrape(@chromeUrl,{},save=true)
    elsif @chromeUrl =~ /taste.com.au/
      taste_scrape(@chromeUrl.gsub(' ','+'),{},save=true)
    elsif @chromeUrl =~ /foodnetwork/
      foodNetwork_scrape(@chromeUrl,{},save=true)
    else @chromeUrl =~ /allrecipes/
      allrecipes_scrape(@chromeUrl,{}, save=true)
      # no match, bookmark instead
    end

  end

  def create
    prep_duration = convert_time_to_seconds((params[:recipe][:prep_duration_hour]).to_i ,(params[:recipe][:prep_duration_mins]).to_i)
    cook_duration = convert_time_to_seconds((params[:recipe][:cook_duration_hour]).to_i,(params[:recipe][:cook_duration_mins]).to_i)

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

  def bbc_scrape(url,r,save=false)
    # raise "hell"
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content'] if (doc.css("meta[itemprop= 'ratingValue']").first['content'])

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

    if save
      @recipe = Recipe.new
      @recipe.title = title
      @recipe.prep_duration = preparation_time
      @recipe.cook_duration = cooking_time
      @recipe.ratings = ratings
      @recipe.level = level
      @recipe.servings = servings
      @recipe.directions = directions
      @recipe.ingredients = ingredients
      @recipe.save
    end

  end

  def taste_scrape(url,r,save=false)
    # raise "jhsbdj"
    # url = /' '/'+'
    doc = Nokogiri::HTML(open(url))
    title = doc.css('.heading > h1').text
    preparation_time = [(doc.css('.prepTime').css('em').text.delete('0:').to_i)*60]
    cooking_time = [(doc.css('.cookTime').css('em').text.delete('0:').to_i)*60]
    # binding.pry
    level = doc.css('.difficultyTitle').css('em').text
    servings = doc.css('.servings').css('em').text
    ratings = doc.css('.rating').css('span.star-level').text
    ingredients = []
    doc.css('.ingredient-table > li > label').each do |i|
      ingredients.push(i.text)
    end
    directions =[]
    doc.css('.method-tab-content > ol > li > p.description').each do |d|
      directions.push(d.text)
    end
    images = doc.css('.recipe-image-wrapper > img').attr('src').text

    if save
        @recipe = Recipe.new
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.ratings = ratings
        @recipe.level = level
        @recipe.servings = servings
        @recipe.directions = directions
        @recipe.ingredients = ingredients
        @recipe.save

    else
    r.merge!( {'title' => title,'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions, 'ingredients' =>  ingredients, 'image_url' => images})
    end


  end

  def allrecipes_scrape(url,r, save=false)
    # scrapeurl = url+'/print'

    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))

    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']

    prep_time= doc.css("time[itemprop='prepTime']").text
    cook_time = doc.css("time[itemprop='cookTime']").text

    servings = doc.css("#metaRecipeServings").first['content']
    directions = []
    doc.css('.recipe-directions__list').css('ol').css('li').each do |step|
     directions.push(step.text.strip)
    end
    if save
        @recipe = Recipe.new
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.ratings = ratings
        @recipe.level = level
        @recipe.servings = servings
        @recipe.ingredients = ingredients
        @recipe.directions = directions
        @recipe.save
    else
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'servings' => servings , 'directions' => directions})

    end
  end


  def foodNetwork_scrape(url,r)
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    # ratings =

    #  $(".gig-rating-stars")[1].title first character

    prep_time= doc.css('.cooking-times > dl >dd:nth-child(4)').text
    if ((prep_time.split(/hrs?/)).size > 1)
     preparation_time = prep_time.split(/hrs?/)
    else
     preparation_time.push(prep_time)
    end
    cook_time = doc.css('.cooking-times > dl >dd:nth-child(6)').text
    if ((cook_time.split(/hrs?/)).size > 1)
     cooking_time = cook_time.split(/hrs?/)
    else
     cooking_time.push(cook_time)
    end
    level = doc.css('.difficulty > dl:nth-child(2) >dd').text
    servings = doc.css('.difficulty > dl:nth-child(1) >dd').text
    ingredients = []
    doc.css(".ingredients > ul > li").each do |i|
      ingredients.push(i.text)
    end
    directions = []
    doc.css(".recipe-directions-list > li > p").each do |d|
      directions.push(d.text)
    end
    if save
        @recipe = Recipe.new
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.ratings = ratings
        @recipe.level = level
        @recipe.servings = servings
        @recipe.ingredients = ingredients
        @recipe.directions = directions
        @recipe.save
    else
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions})
    end
  end

end
