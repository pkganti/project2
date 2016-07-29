class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :emailid
      t.string :password
      t.boolean :isAdmin
      t.text :image

      t.timestamps null: false
    end
  end
end
