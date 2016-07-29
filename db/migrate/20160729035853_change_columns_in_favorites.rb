class ChangeColumnsInFavorites < ActiveRecord::Migration
  def change
    rename_column :favorites, :userId, :user_id
    rename_column :favorites, :recipeId, :recipe_id
  end
end
