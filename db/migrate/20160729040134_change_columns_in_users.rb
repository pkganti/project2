class ChangeColumnsInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :emailid, :email
  end
end
