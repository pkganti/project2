class ChangeUseridInRecipes < ActiveRecord::Migration
  def change
    rename_column :recipes, :userId, :user_id
  end
end
