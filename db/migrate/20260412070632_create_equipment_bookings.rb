class CreateEquipmentBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_bookings do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :equipment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
