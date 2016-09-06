class ChangeServingstypeToRecipes < ActiveRecord::Migration
  def change
    change_column :recipes, :servings, :string
  end
end
