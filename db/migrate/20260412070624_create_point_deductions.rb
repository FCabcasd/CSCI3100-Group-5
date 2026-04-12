class CreatePointDeductions < ActiveRecord::Migration[8.1]
  def change
    create_table :point_deductions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :booking, null: true, foreign_key: true
      t.integer :points
      t.string :reason

      t.timestamps
    end
  end
end
