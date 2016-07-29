class CreateAddFieldsToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :servings, :integer
    add_column :recipes, :source_url, :text
    add_column :recipes, :prep_duration, :integer
    rename_column :recipes, :duration, :cook_duration
  end
end
