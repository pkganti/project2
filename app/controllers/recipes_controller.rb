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
      @list_recipes = @recipes.sample(5)

    end
  end

  def show
    f2fkey="18eb516313da0e6e327844bf73c1c8e0"
    url2 = "http://food2fork.com/api/get?key=#{f2fkey}&rId=#{params[:id]}"
    string_obj = HTTParty.get(url2)
    object_obj = JSON.parse(string_obj)
    @searchrecipe = object_obj

      if (@searchrecipe["recipe"]).present?
        if @searchrecipe["recipe"]["source_url"] =~ /bbcgoodfood/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          @searchrecipe  = bbc_scrape(source_url,recipeObj)

        elsif @searchrecipe["recipe"]["source_url"] =~ /allrecipes/
          source_url = @searchrecipe["recipe"]["source_url"]
          recipeObj = @searchrecipe["recipe"]
          @searchrecipe  = allrecipes_scrape(source_url,recipeObj)
        end
        # binding.pry
      else
        @recipe = Recipe.find_by( :id => params[:id])
        @quantities = Quantity.where(:recipe_id => params[:id])
        @all_ratings = Rate.where(:rateable_id => @recipe.id).pluck(:stars)
        @recipe_avg_rating = ratings_avg(@recipe.id)
        @recipe_rating = (Rate.where(:rateable_id => @recipe.id , :rater_id => @recipe.user_id)).pluck(:stars)[0]
      end

  end

  def new
    @recipe = Recipe.new

     3.times { @recipe.ingredients.build }
  end

  def bookmark

    existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id).last #where is returning an array. Using last to get into the recipe
    if existing_recipe.present?

      existing_recipe.cuisine = params.fetch(:cuisine)
      existing_recipe.category = params.fetch(:category)
      existing_recipe.save
      render json: recipe_url(existing_recipe.id),  :status => 200

    else
      recipe = Recipe.new
      recipe.source_url = params.fetch(:url)
      recipe.title = params.fetch(:title)
      recipe.cuisine = params.fetch(:cuisine)
      recipe.category = params.fetch(:category)
      recipe.prep_duration = convert_time_to_seconds(params.fetch(:prep_duration_hour), params.fetch(:prep_duration_mins))
      recipe.cook_duration = convert_time_to_seconds(params.fetch(:cook_duration_hour), params.fetch(:cook_duration_mins))
      recipe.user = @current_user
      recipe.images = params.fetch(:images)
      recipe.save
      render json: recipe_url(recipe.id),  :status => 200
    end
  end

  def scrape
    if @current_user.present?
      existing_recipe = Recipe.where(:source_url => params.fetch(:url), :user_id => @current_user.id)

      if existing_recipe.present?
        render json: 'alreadyExists', :status => 200

        return
      end

      @chromeUrl =  params.fetch(:url)
      if @chromeUrl =~ /bbcgoodfood\.com/
        new_id = bbc_scrape(@chromeUrl,{},save=true)
        # @recipe = Recipe.find_by :id => new_id
        # @recipe.cuisine = params.fetch(:)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /taste\.com\.au/
        new_id = taste_scrape(@chromeUrl.gsub(' ','+'),{},save=true)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /foodnetwork\.com/
        new_id = foodNetwork_scrape(@chromeUrl,{},save=true)
        status = recipe_url(new_id)
      elsif @chromeUrl =~ /allrecipes\.com/
        new_id = allrecipes_scrape(@chromeUrl,{}, save=true)
        status = recipe_url(new_id)
      else
        status = 'notok'
      end

      render json: status,  :status => 200
    else
      render json: 'needtologin',  :status => 200

    end

  end

  def create
    prep_duration = convert_time_to_seconds((params[:recipe][:prep_duration_hour]).to_i ,(params[:recipe][:prep_duration_mins]).to_i)
    cook_duration = convert_time_to_seconds((params[:recipe][:cook_duration_hour]).to_i,(params[:recipe][:cook_duration_mins]).to_i)

    @recipe = Recipe.create recipe_params
    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
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

    if (params[:file]).present?
      req = Cloudinary::Uploader.upload(params[:file])
      @recipe.images = req["url"]
    end
    @recipe.update recipe_params

    redirect_to @recipe
  end

  def destroy
    recipe = Recipe.find_by(:id => params[:id])
    recipe.isActive = false
    recipe.save

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
    # binding.pry
    # raise "hell"
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    title = doc.css('.recipe-header__title').text
    if (doc.css("meta[itemprop= 'ratingValue']")).present?
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content'] if (doc.css("meta[itemprop= 'ratingValue']").first['content'])
  end
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

    ingredients = []
    doc.css("[itemprop='ingredients']").each do |i|
      if save
        ingr = Ingredient.new
        ingr.name = i.text
        ingr.save
        ingredients.push(ingr)
      else
        ingredients.push(i.text)
      end

    end



   images = doc.css("[itemprop = 'image']").attr('src').text
   if save
     @recipe = Recipe.new
     @recipe.title = title
     @recipe.prep_duration = preparation_time
     @recipe.images = images
     @recipe.cook_duration = cooking_time
     @recipe.ratings = ratings
     @recipe.level = level
     @recipe.servings = servings
     @recipe.directions = directions.join(',')
     if ingredients.length > 0
       @recipe.ingredients << ingredients
     end
     @recipe.user_id = @current_user.id
     @recipe.source_url = url
     @recipe.save
     @recipe.id
   else
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions})

  end

  end

  def taste_scrape(url,r,save=false)
    # raise "jhsbdj"
    # url = /' '/'+'
    doc = Nokogiri::HTML(open(url))
    # raise 'hell'
    title = doc.css('.heading > h1').text
    # prep_time = (doc.css('.prepTime').css('em').text.split(':'))
    # cook_time = (doc.css('.cookTime').css('em').text.split(':'))
    # binding.pry
    preparation_time = [(doc.css('.prepTime').css('em').text.delete('0:').to_i)*60]
    cooking_time = [(doc.css('.cookTime').css('em').text.delete('0:').to_i)*60]
    level = doc.css('.difficultyTitle').css('em').text
    servings = doc.css('.servings').css('em').text
    ratings = doc.css('.rating').css('span.star-level').text
    ingredients = []
    doc.css('.ingredient-table > li > label').each do |i|
      if save
        ingr = Ingredient.new
        ingr.name = i.text
        ingr.save
        ingredients.push(ingr)
      else
        ingredients.push(i.text)
      end
    end
    # File.write('../../taste_scrape_log.txt')
    directions =[]
    doc.css('.method-tab-content > ol > li > p.description').each do |d|
      # binding.pry
      directions.push(d.text.remove('[').remove(']'))
    end
    # binding.pry
    images = doc.css('.recipe-image-wrapper > img').attr('src').text
    if save
        @recipe = Recipe.new
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.ratings = ratings
        @recipe.images = images
        @recipe.level = level
        @recipe.servings = servings
        @recipe.directions = directions.join(',')
        @recipe.source_url = url
        if ingredients.length > 0
          @recipe.ingredients << ingredients
        end
         @recipe.user_id = @current_user.id
        @recipe.save
        @recipe.id
    else
    r.merge!( {'title' => title,'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions, 'ingredients' =>  ingredients, 'image_url' => images})
    end
  end

  def allrecipes_scrape(url,r, save=false)
    # scrapeurl = url+'/print'

    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    # raise "hell"
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']
    title = doc.css('.recipe-summary__h1').text
    images = doc.css('.rec-photo').attr('src').text

    preparation_time_raw= (doc.css("time[itemprop='prepTime']").text).split(' ')
    preparation_time = [(preparation_time_raw[0]).to_i * 60] if (preparation_time_raw.last).eql?'m'
    preparation_time = [((preparation_time_raw[0]).to_i * 60 *60)] if (preparation_time_raw.last).eql?'h'
    cooking_time_raw = (doc.css("time[itemprop='cookTime']").text).split(' ')
    # cooking_time = [(cooking_time_raw[0]).to_i * 60] if (cooking_time_raw.last).eql?'m'
    # cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60)] if (cooking_time_raw.last).eql?'h'
    if (cooking_time_raw.join(',').include?'h') && (cooking_time_raw.join(',').include?'m')

      cooking_time = [(cooking_time_raw[0]).to_i * 60 * 60 + ((cooking_time_raw[2]).to_i * 60 )]
    elsif ((cooking_time_raw.last).eql?'m')
      cooking_time = [(cooking_time_raw[0]).to_i * 60]
    elsif ((cooking_time_raw.last).eql?'h')
      cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60)]
    end


    # binding.pry
    servings = doc.css("#metaRecipeServings").first['content']

    ingredients = []
    doc.css('.recipe-ingredients > ul > li > label').each do |i|
      if save
        ingr = Ingredient.new
        ingr.name = i.text
        ingr.save
        ingredients.push(ingr)
      else
        ingredients.push(i.text)
      end
    end
    #
    # ingredients.reject! { |i| i.empty? }

    directions = []
    doc.css('.recipe-directions__list').css('ol').css('li').each do |step|
     directions.push(step.text.strip)
    end

    # raise "hell"

    images = doc.css(".rec-photo").attr('src').text
    if save
        @recipe = Recipe.new
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.ratings = ratings
        @recipe.images = images
        # @recipe.level = level
        @recipe.servings = servings
        if ingredients.length > 0
          @recipe.ingredients << ingredients
        end
        @recipe.directions = directions.join(',')
        @recipe.source_url = url
        @recipe.user_id = @current_user.id
        @recipe.save
        @recipe.id
    else
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'servings' => servings , 'directions' => directions})

    end
  end


  def foodNetwork_scrape(url,r, save=true)
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    title= doc.css('div.title > h1').text
    # ($(".gig-rating-stars")[1].title).split(' ')[0]
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
    images = doc.css('div .photo-video figure div a div img').attr('src').text
    ingredients = []
    doc.css(".ingredients > ul > li").each do |i|
      if save
        ingr = Ingredient.new
        ingr.name = i.text
        ingr.save
        ingredients.push(ingr)
      else
        ingredients.push(i.text)
      end
    end
    directions = []
    doc.css(".recipe-directions-list > li > p").each do |d|
      directions.push(d.text)
    end
    # binding.pry
    if save
        @recipe = Recipe.new
        @recipe.images = images
        @recipe.title = title
        @recipe.prep_duration = preparation_time
        @recipe.cook_duration = cooking_time
        @recipe.level = level
        @recipe.servings = servings
        if ingredients.length > 0
          @recipe.ingredients << ingredients
        end
        @recipe.directions = directions.join(',')
        @recipe.source_url = url
        @recipe.user_id = @current_user.id
        @recipe.save
        @recipe.id
    else
    r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions})
    end
  end

  def ratings_avg(recipe_id)
    ratings = Rate.where(:rateable_id => recipe_id).pluck(:stars)
    # binding.pry
    if (ratings.size > 0)
      avg = (ratings.sum)/(ratings.size)
    end
  end

end
