class CreateCancellations < ActiveRecord::Migration[8.1]
  def change
    create_table :cancellations do |t|
      t.references :booking, null: false, foreign_key: true
      t.datetime :cancelled_at
      t.float :hours_before_start
      t.text :reason
      t.boolean :is_late_cancellation, default: false
      t.integer :points_deducted, default: 0

      t.timestamps
    end
  end
end
