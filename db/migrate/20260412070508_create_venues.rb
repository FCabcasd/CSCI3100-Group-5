class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :capacity
      t.string :location
      t.float :latitude
      t.float :longitude
      t.json :features, default: {}
      t.string :image_url
      t.string :available_from, default: '08:00'
      t.string :available_until, default: '22:00'
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
