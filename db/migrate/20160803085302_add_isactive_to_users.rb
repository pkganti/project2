class AddIsactiveToUsers < ActiveRecord::Migration
  def change
    add_column :users, :isActive, :boolean, default:true
    add_column :recipes, :isActive, :boolean, default:true
  end
end
