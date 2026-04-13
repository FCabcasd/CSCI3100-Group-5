class ConflictDetectionService
  def self.check_venue_availability(venue_id:, start_time:, end_time:, exclude_booking_id: nil)
    scope = Booking.where(venue_id: venue_id)
                   .where(status: [ :pending, :confirmed ])
                   .where("start_time < ? AND end_time > ?", end_time, start_time)

    scope = scope.where.not(id: exclude_booking_id) if exclude_booking_id

    conflict = scope.first
    if conflict
      [ false, "Venue is booked from #{conflict.start_time} to #{conflict.end_time}" ]
    else
      [ true, nil ]
    end
  end

  def self.check_equipment_availability(equipment_id:, start_time:, end_time:, exclude_booking_id: nil)
    equipment = Equipment.find_by(id: equipment_id)
    return [ false, "Equipment not found" ] unless equipment

    scope = Booking.joins(:equipment_bookings)
                   .where(equipment_bookings: { equipment_id: equipment_id })
                   .where(status: [ :pending, :confirmed ])
                   .where("bookings.start_time < ? AND bookings.end_time > ?", end_time, start_time)

    scope = scope.where.not(id: exclude_booking_id) if exclude_booking_id

    booked_count = scope.count
    if booked_count >= equipment.quantity
      [ false, "Equipment is already fully booked at this time" ]
    else
      [ true, nil ]
    end
  end

  def self.validate_booking_times(venue_id:, equipment_ids:, start_time:, end_time:, exclude_booking_id: nil)
    available, msg = check_venue_availability(
      venue_id: venue_id, start_time: start_time, end_time: end_time,
      exclude_booking_id: exclude_booking_id
    )
    return [ false, msg ] unless available

    (equipment_ids || []).each do |eq_id|
      available, msg = check_equipment_availability(
        equipment_id: eq_id, start_time: start_time, end_time: end_time,
        exclude_booking_id: exclude_booking_id
      )
      return [ false, msg ] unless available
    end

    [ true, nil ]
  end
end
