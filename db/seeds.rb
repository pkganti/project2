User.destroy_all
u1 = User.create(:name => "Tripti", :password => "chicken", :password_confirmation => 'chicken', :email => "tripti.895@gmail.com", :isAdmin =>true, :image => "https://media.licdn.com/mpr/mpr/shrinknp_400_400/AAEAAQAAAAAAAAj5AAAAJDI5NWE1NDA0LWMzZTItNDI2NC04MThhLTBjOTJhZDhmODExYw.jpg")
u2 = User.create(:name => "Phani", :password => "chicken", :password_confirmation => 'chicken', :email => "ganti.phani@gmail.com", :isAdmin =>false, :image =>"http://res.cloudinary.com/sydjs/image/upload/c_thumb,f_auto,g_faces,h_360,w_360/v1465866066/gc0esgwzwcog58px8xfz.jpg")
u3 = User.create(:name => "Katrina", :password => "chicken", :password_confirmation => 'chicken', :email => "katrinamarielee@gmail.com", :isAdmin =>false, :image =>"http://www.checkmate.io/wordpress/wp-content/uploads/2015/05/Katrina_Marie_Lee.png")
Recipe.destroy_all
r1 = Recipe.create(:title => "Honey-soy chicken", :ratings => 5, :category => "poultry", :cuisine => "Asian", :cook_duration => 3600, :level => "easy", :images => "http://www.taste.com.au/images/recipes/sfi/2011/04/honeysoy-chicken-21995_l.jpeg", :directions => "Step 1
Combine soy sauce, honey, ginger and garlic in a large dish. Add chicken. Turn to coat. Cover with plastic wrap. Refrigerate for 2 hours, turning occasionally.
Step 2
Preheat oven to 200°C/180°C fan-forced. Line a baking tray with baking paper.
Step 3
Remove chicken from marinade. Place, in a single layer, on prepared tray. Sprinkle with sesame seeds. Bake for 35 minutes or until golden and cooked through. Serve with Fried rice (see related recipe).",:user_id => 2)
r2 = Recipe.create(:title => "Mac And Four Cheeses", :ratings => 4, :category => "pasta", :cuisine => "American", :cook_duration => 1800, :level => "easy", :images => "http://foodnetwork.sndimg.com/content/dam/images/food/fullset/2003/11/12/0/ee2c04_macaroni_4_cheese.jpg.rend.sni18col.jpeg", :directions => "Cook the macaroni according to the package directions in lightly salted water, leaning toward the al dente side. Do not overcook!
Put the cream, butter and garlic clove into a Dutch oven and heat on the stove over low heat. When the cream is hot, add the fontina, goat cheese, Parmesan and Romano.
Drain the macaroni (reserving some of the cooking water if needed) and add it to the pot. Stir gently to combine, adding hot macaroni water as needed for consistency. Don't overmix; if there are little clumps of cheese here and there, it's fine! Taste and add about 1/2 teaspoon salt if needed. Add some pepper and minced parsley and stir. Serve immediately.
If you are eating it later, turn the mixture into a large, buttered ovenproof dish. Sprinkle over some extra grated fontina and bake at 350 degrees F until bubbly and golden on top, 20 to 25 minutes. Sprinkle with parsley and serve.
Recipe courtesy of Ree Drummond
", :user_id => 3)
r3 = Recipe.create(:title => "Potato and leek soup", :ratings => 4.3, :category => "soup", :cook_duration => 6600, :level => "easy", :images => "http://www.taste.com.au/images/recipes/agt/2004/04/potato-and-leek-soup-5910_l.jpeg", :directions => "Step 1
Heat 1 tablespoon of the oil in a large saucepan over medium-high heat. Add the onion and garlic and cook, stirring, for 3 minutes or until the onion softens. Add the potato and leek and cook, stirring, for 5 minutes or until leek softens.
Step 2
Add the stock and bring to the boil. Reduce heat to medium and gently boil, uncovered, for 20 minutes or until potato is soft. Remove from heat and set aside for 10 minutes to cool.
Step 3
Meanwhile, preheat oven to 200C or 180C fan-forced. Place bread in a roasting pan. Drizzle with remaining oil and toss until bread is evenly coated. Toast in preheated oven, shaking pan occasionally, for 10-15 minutes or until crisp. Remove croutons from oven and set aside.
Step 4
Transfer one-third of the potato mixture to the jug of a blender and blend until smooth. Transfer to a clean saucepan. Repeat in 2 more batches with the remaining potato mixture.
Step 5
Place the soup over medium heat. Add the cream and stir to combine. Cook, stirring, for 5 minutes or until hot. Taste and season with salt.
Step 6
Ladle the soup among serving bowls. Sprinkle with chives and top with croutons. Serve immediately.", :user_id => 1)
Quantity.destroy_all
q1 = Quantity.create(:unit => "gram", :size => 1000, :recipe_id =>1 , :ingredient_id =>1)
q2 = Quantity.create(:unit => "cup", :size => 0.5, :recipe_id =>1 , :ingredient_id =>2)
q3 = Quantity.create(:unit => "cup", :size => 0.33, :recipe_id =>1 , :ingredient_id =>3)

q4 = Quantity.create(:unit => "gram", :size => 100, :recipe_id =>2 , :ingredient_id =>4)
q5 = Quantity.create(:unit => "gram", :size => 200, :recipe_id =>2 , :ingredient_id =>5)

q6 = Quantity.create(:unit => "gram", :size => 500, :recipe_id =>3 , :ingredient_id =>6)
q7 = Quantity.create(:unit => "gram", :size => 100, :recipe_id =>3 , :ingredient_id =>7)
q8 = Quantity.create(:unit => "ml", :size => 100, :recipe_id =>3 , :ingredient_id =>8)
q9 = Quantity.create(:unit => "gram", :size => 100, :recipe_id =>3 , :ingredient_id =>1)

Ingredient.destroy_all
i1= Ingredient.create(:name => "Chicken", :category => "Poultry")
i2= Ingredient.create(:name => "Soy Sauce", :category => "Condiments and Sauces")
i3= Ingredient.create(:name => "Honey", :category => "Condiments and Sauces")
i4= Ingredient.create(:name => "Macaroni", :category => "pasta")
i5= Ingredient.create(:name => "Fontina Cheese", :category => "dairy")
i6= Ingredient.create(:name => "Potato", :category => "vegetable")
i7= Ingredient.create(:name => "Leek", :category => "vegetable")
i8= Ingredient.create(:name => "Cream", :category => "Dairy")

Favorite.destroy_all
f1 = Favorite.create(:recipe_id =>3 , :user_id =>2)
f2 = Favorite.create(:recipe_id =>2 , :user_id =>1)
