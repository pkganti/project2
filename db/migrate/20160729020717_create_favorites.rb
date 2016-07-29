class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.integer :userId
      t.integer :recipeId

      t.timestamps null: false
    end
  end
end
