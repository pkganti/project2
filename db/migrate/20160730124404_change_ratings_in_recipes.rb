class ChangeRatingsInRecipes < ActiveRecord::Migration
  def change
    change_column :recipes, :ratings, :float
  end
end
