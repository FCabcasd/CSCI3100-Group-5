class CreateEquipment < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :quantity, default: 1
      t.string :equipment_type
      t.string :status, default: 'available'
      t.string :image_url
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
