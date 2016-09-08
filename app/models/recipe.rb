class Recipe < ActiveRecord::Base
  belongs_to :user
  has_many :ingredients, :through => :quantities
  has_many :quantities
  has_many :favorites
  accepts_nested_attributes_for :quantities, allow_destroy: true
  accepts_nested_attributes_for :ingredients, allow_destroy: true
  ratyrate_rateable 'useful'

def self.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)
#method for creating a new recipe that comes from an extension search
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
  @recipe.user_id = user.id
  @recipe
end

def self.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
#render the recipe fields when a recipe is found from the food2fork api
    r.merge!( {'title' => title,'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions, 'ingredients' =>  ingredients,'quantities' => '', 'images' => images})
end

def self.taste_scrape(url,r,save=false,user)
#Nokogiri scrape for Taste.com.au. Traverse DOM for each recipe field
  doc = Nokogiri::HTML(open(url))
  title = doc.css('.heading > h1').text
  #Extract the prep time to be an integer and multiply 60 for time in seconds
  preparation_time = [((doc.css('.prepTime').css('em').text.delete('0:').to_i)*60)]
  #Extract the cook time to be an integer and multiply 60 for time in seconds
  cooking_time = [((doc.css('.cookTime').css('em').text.delete('0:').to_i)*60)]
  level = doc.css('.difficultyTitle').css('em').text
  servings = doc.css('.servings').css('em').text
  ratings = doc.css('.rating').css('span.star-level').text
  ingredients = []
  #for each ingredient save as new ingredient to database
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
  #for each line of direction create a new paragraph for directions
  directions =[]
  doc.css('.method-tab-content > ol > li > p.description').each do |d|
    directions.push(d.text.remove('[').remove(']'))
  end
  images = doc.css('.recipe-image-wrapper > img').attr('src').text
  if save.eql?true
    #Now that recipe fields are scraped from the extension, save as a new recipe

    @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time[0], cooking_time[0], ratings, images, level, servings, directions, url, ingredients,user)

    @recipe.save
    @recipe.id
  else
    #Recipe fields are scraped for recipes found through the food2fork API
    Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
  end
end

  def self.bbc_scrape(url,r,save=false,user)
    preparation_time=[]
    cooking_time =[]
    # (@searchrecipe["recipe"]).merge!( {'level' => 'Easy'})
    doc = Nokogiri::HTML(open(url))
    title = doc.css('.recipe-header__title').text
    if (doc.css("meta[itemprop= 'ratingValue']")).present?
      ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content'] if (doc.css("meta[itemprop= 'ratingValue']").first['content'])
    end
    #for prep time, if the prep time has hours or mins, extract the integer and convert to seconds
    preping_time_raw= doc.css('.recipe-details__cooking-time-prep > span').text.split(' ')
    if (preping_time_raw.join(',').include?'hrs') && (preping_time_raw.join(',').include?'mins')

      preparation_time = [((preping_time_raw[0]).to_i * 60 * 60 + ((preping_time_raw[2]).to_i * 60 )).to_s]
    elsif ((preping_time_raw.last).eql?'mins')
      preparation_time = [((preping_time_raw[0]).to_i * 60).to_s]
    elsif ((preping_time_raw.last).eql?'hrs')
      preparation_time = [(((preping_time_raw[0]).to_i * 60 * 60)).to_s]
    end
    #for cook time, if the cook time has hours or mins, extract the integer and convert to seconds
    cooking_time_raw = doc.css('.recipe-details__cooking-time-cook > span').text.split(' ')

    if (cooking_time_raw.join(',').include?'hrs') && (cooking_time_raw.join(',').include?'mins')
      cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60 + ((cooking_time_raw[2]).to_i * 60 )).to_s]
    elsif ((cooking_time_raw.last).eql?'mins')
      cooking_time = [((cooking_time_raw[0]).to_i * 60).to_s]
    elsif ((cooking_time_raw.last).eql?'hrs')
      cooking_time = [(((cooking_time_raw[0]).to_i * 60 * 60)).to_s]
    end
    level = doc.css('.recipe-details__item--skill-level').css('span').text.strip
    servings = doc.css('.recipe-details__item--servings').css('span').text.strip
    directions = []
    #For each direction step, push into directions and separate each step with a line break
    doc.css('#recipe-method').css('ol').each do |step|
     directions.push(step.css('li').text.strip.gsub("\n", '<br>'))
    end

    ingredients = []
    #For ingredient, create new ingredient in the database
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
     #Now that recipe fields are scraped from the extension, save as a new recipe
     @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time[0], cooking_time[0], ratings, images, level, servings, directions, url, ingredients,user)
     @recipe.save
     @recipe.id
   else
     #Recipe fields are scraped for recipes found through the food2fork API
     Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time[0],cooking_time[0],level,servings,directions,ingredients,images)

   end

  end

  def self.allrecipes_scrape(url,r, save=false,user)
    #Nokogiri scrape for AllRecipes.com. Traverse DOM for each recipe field.
    doc = Nokogiri::HTML(open(url))
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']
    title = doc.css('.recipe-summary__h1').text
    images = doc.css('.rec-photo').attr('src').text
    level = 'Easy'
    #Where m (minutes is found) multiply integer to get prep time in seconds, similarly for h (hours)
    preparation_time_raw= (doc.css("time[itemprop='prepTime']").text).split(' ')
    preparation_time = [((preparation_time_raw[0]).to_i * 60).to_s] if (preparation_time_raw.last).eql?'m'
    preparation_time = [(((preparation_time_raw[0]).to_i * 60 *60)).to_s] if (preparation_time_raw.last).eql?'h'
    #Where m (minutes is found) multiply integer to get cook time in seconds, similarly for h (hours)
    cooking_time_raw = (doc.css("time[itemprop='cookTime']").text).split(' ')
    if (cooking_time_raw.join(',').include?'h') && (cooking_time_raw.join(',').include?'m')
      cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60 + ((cooking_time_raw[2]).to_i * 60 )).to_s]
    elsif ((cooking_time_raw.last).eql?'m')
      cooking_time = [((cooking_time_raw[0]).to_i * 60).to_s]
    elsif ((cooking_time_raw.last).eql?'h')
      cooking_time = [(((cooking_time_raw[0]).to_i * 60 * 60)).to_s]
    end

    servings = doc.css("#metaRecipeServings").first['content']

    ingredients = []
    #For each ingredient create a new ingredient in the database
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

    directions = []
    doc.css('.recipe-directions__list').css('ol').css('li').each do |step|
     directions.push(step.text.strip)
    end

    images = doc.css(".rec-photo").attr('src').text
    if save
      #Now that recipe fields are scraped from the extension, save as a new recipe
      @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time[0], cooking_time[], ratings, images, level, servings, directions, url, ingredients,user)
      @recipe.save
      @recipe.id
    else
     #Recipe fields are scraped for recipes found through the food2fork API and ready to be rendered
     Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time[0],cooking_time[0],level,servings,directions,ingredients,images)
    end
  end


  def self.foodNetwork_scrape(url,r, save=true,user)
  #Nokogiri scrape for Food Network. Traverse DOM for each recipe field.
    preparation_time=[]
    cooking_time =[]
    doc = Nokogiri::HTML(open(url))
    title= doc.css('div.title > h1').text
    prep_time= doc.css('.cooking-times > dl >dd:nth-child(4)')[0].text
    #Find prep time and extract integers corresponding to hour or minutes and convert to seconds
    if ((prep_time.split(/hr*/)).size > 0)
     preparation_time.push((prep_time.split(' ')[0]).to_i * 60 )
    elsif ((prep_time.split(/min*/)).size > 0)
     preparation_time.push((prep_time.split(' ')[0]).to_i )
    else
     preparation_time.push(prep_time)
    end
    #Find cook time and extract integers corresponding to hour or minutes and convert to seconds
    cook_time = doc.css('.cooking-times > dl >dd:nth-child(6)')[0].text
    if ((cook_time.split(/hr*/)).size > 0)
      cooking_time.push((cook_time.split(' ')[0]).to_i * 60)
    elsif ((cook_time.split(/min*/)).size > 1)
      cooking_time.push((cook_time.split(' ')[0]).to_i)
    else
     cooking_time.push(cook_time)
    end
    level = doc.css('.difficulty > dl:nth-child(2) >dd')[0].text
    servings = doc.css('.difficulty > dl:nth-child(1) >dd')[0].text
    images = doc.css('div .photo-video img').attr('src').text
    ratings = ""
    ingredients = []
    #For each ingredient, create new ingredient in database
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

    if save
      #Now that recipe fields are scraped from the extension, save as a new recipe
      @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time[0], cooking_time[0], ratings, images, level, servings, directions, url, ingredients,user)
      @recipe.save
      @recipe.id
    else
      #If recipe is found via the API
       Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time[0],cooking_time[0],level,servings,directions,ingredients,images)
    end
  end
end
