class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :is_recurring, default: false
      t.string :recurrence_pattern
      t.datetime :recurrence_end_date
      t.integer :parent_booking_id
      t.string :contact_person
      t.string :contact_email
      t.string :contact_phone
      t.integer :estimated_attendance
      t.text :special_requirements
      t.datetime :cancelled_at
      t.text :cancellation_reason

      t.timestamps
    end
    add_index :bookings, [:start_time, :end_time]
    add_index :bookings, :status
  end
end
