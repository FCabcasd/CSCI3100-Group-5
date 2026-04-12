class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true
      t.integer :cancellation_deadline_hours, default: 24
      t.integer :point_deduction_per_late_cancel, default: 10
      t.integer :max_recurring_days, default: 180

      t.timestamps
    end
    add_index :tenants, :name, unique: true
  end
end
