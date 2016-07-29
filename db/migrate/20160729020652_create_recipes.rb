class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :title
      t.text :directions
      t.integer :duration
      t.decimal :ratings
      t.string :category
      t.string :cuisine
      t.text :images
      t.integer :level
      t.integer :userId

      t.timestamps null: false
    end
  end
end
