class ChangeVenueIdNullableOnBookings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bookings, :venue_id, true
  end
end
