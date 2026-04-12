class AddCheckInToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :checked_in_at, :datetime
  end
end
