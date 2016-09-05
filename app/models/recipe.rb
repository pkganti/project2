class Recipe < ActiveRecord::Base
  belongs_to :user
  has_many :ingredients, :through => :quantities
  has_many :quantities
  has_many :favorites
  accepts_nested_attributes_for :quantities, allow_destroy: true
  accepts_nested_attributes_for :ingredients, allow_destroy: true
  ratyrate_rateable 'useful'

def self.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)

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
  # @recipe.save
  # @recipe.id
  @recipe
end

def self.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
    r.merge!( {'title' => title,'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions, 'ingredients' =>  ingredients, 'images' => images})
end

def self.taste_scrape(url,r,save=false,user)
  # raise "jhsbdj"
  # url = /' '/'+'
  doc = Nokogiri::HTML(open(url))
  # raise 'hell'
  title = doc.css('.heading > h1').text
  # prep_time = (doc.css('.prepTime').css('em').text.split(':'))
  # cook_time = (doc.css('.cookTime').css('em').text.split(':'))
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
  if save.eql?true
    @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)
    @recipe.save
    @recipe.id
  else
    Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
  # r.merge!( {'title' => title,'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions, 'ingredients' =>  ingredients, 'images' => images})
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
    preping_time_raw= doc.css('.recipe-details__cooking-time-prep > span').text.split(' ')
    if (preping_time_raw.join(',').include?'hrs') && (preping_time_raw.join(',').include?'mins')

      preparation_time = [(preping_time_raw[0]).to_i * 60 * 60 + ((preping_time_raw[2]).to_i * 60 )]
    elsif ((preping_time_raw.last).eql?'mins')
      preparation_time = [(preping_time_raw[0]).to_i * 60]
    elsif ((preping_time_raw.last).eql?'hrs')
      preparation_time = [((preping_time_raw[0]).to_i * 60 * 60)]
    end
    # if ((prep_time.split(/hrs?/)).size > 1)
    #  preparation_time = prep_time.split(/hrs?/)
    # else
    #  preparation_time.push(prep_time)
    # end
    cooking_time_raw = doc.css('.recipe-details__cooking-time-cook > span').text.split(' ')
    # binding.pry
    if (cooking_time_raw.join(',').include?'hrs') && (cooking_time_raw.join(',').include?'mins')

      cooking_time = [(cooking_time_raw[0]).to_i * 60 * 60 + ((cooking_time_raw[2]).to_i * 60 )]
    elsif ((cooking_time_raw.last).eql?'mins')
      cooking_time = [(cooking_time_raw[0]).to_i * 60]
    elsif ((cooking_time_raw.last).eql?'hrs')
      cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60)]
    end
    # if ((cook_time.split(/hrs?/)).size > 1)
    #  cooking_time = cook_time.split(/hrs?/)
    # else
    #  cooking_time.push(cook_time)
    # end
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
     @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)
     @recipe.save
     @recipe.id
   else
     Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)

  end

  end

  def self.allrecipes_scrape(url,r, save=false,user)
    doc = Nokogiri::HTML(open(url))
    ratings =  doc.css("meta[itemprop= 'ratingValue']").first['content']
    title = doc.css('.recipe-summary__h1').text
    images = doc.css('.rec-photo').attr('src').text
    level = 'Easy'
    preparation_time_raw= (doc.css("time[itemprop='prepTime']").text).split(' ')
    preparation_time = [(preparation_time_raw[0]).to_i * 60] if (preparation_time_raw.last).eql?'m'
    preparation_time = [((preparation_time_raw[0]).to_i * 60 *60)] if (preparation_time_raw.last).eql?'h'
    cooking_time_raw = (doc.css("time[itemprop='cookTime']").text).split(' ')
    if (cooking_time_raw.join(',').include?'h') && (cooking_time_raw.join(',').include?'m')

      cooking_time = [(cooking_time_raw[0]).to_i * 60 * 60 + ((cooking_time_raw[2]).to_i * 60 )]
    elsif ((cooking_time_raw.last).eql?'m')
      cooking_time = [(cooking_time_raw[0]).to_i * 60]
    elsif ((cooking_time_raw.last).eql?'h')
      cooking_time = [((cooking_time_raw[0]).to_i * 60 * 60)]
    end

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

    directions = []
    doc.css('.recipe-directions__list').css('ol').css('li').each do |step|
     directions.push(step.text.strip)
    end

    images = doc.css(".rec-photo").attr('src').text
    if save
      @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)
      @recipe.save
      @recipe.id
    else
     Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
    end
  end


  def self.foodNetwork_scrape(url,r, save=true,user)
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

    if save
      @recipe = Recipe.save_extension_scrape_recipe(title,preparation_time, cooking_time, ratings, images, level, servings, directions, url, ingredients,user)
      @recipe.save
      @recipe.id
    else
       Recipe.save_api_scrape_recipe(r,title,ratings,preparation_time,cooking_time,level,servings,directions,ingredients,images)
    #     @recipe = Recipe.new
    #     @recipe.images = images
    #     @recipe.title = title
    #     @recipe.prep_duration = preparation_time
    #     @recipe.cook_duration = cooking_time
    #     @recipe.level = level
    #     @recipe.servings = servings
    #     if ingredients.length > 0
    #       @recipe.ingredients << ingredients
    #     end
    #     @recipe.directions = directions.join(',')
    #     @recipe.source_url = url
    #     @recipe.user_id = user.id
    #     @recipe.save
    #     @recipe.id
    # else
    # r.merge!( {'ratings' => ratings , 'prep_duration' => preparation_time ,'cook_duration' => cooking_time , 'level' => level , 'servings' => servings , 'directions' => directions})
    end
  end
end
