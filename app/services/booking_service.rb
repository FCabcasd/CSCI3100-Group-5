class BookingService
  def self.create_booking(user:, params:)
    equipment_ids = params.delete(:equipment_ids) || []

    # Parse time strings to Time objects for proper comparison
    start_time = params[:start_time].is_a?(String) ? Time.parse(params[:start_time]) : params[:start_time]
    end_time = params[:end_time].is_a?(String) ? Time.parse(params[:end_time]) : params[:end_time]

    available, msg = ConflictDetectionService.validate_booking_times(
      venue_id: params[:venue_id],
      equipment_ids: equipment_ids,
      start_time: start_time,
      end_time: end_time
    )
    raise StandardError, msg unless available

    raise StandardError, "Insufficient points to book" if user.points < 10

    booking = user.bookings.build(params.merge(status: :pending, start_time: start_time, end_time: end_time))

    if equipment_ids.present?
      equipment = Equipment.where(id: equipment_ids)
      booking.equipment_list = equipment
    end

    booking.save!
    BookingMailer.booking_confirmation(booking).deliver_later
    booking
  end

  def self.create_recurring_booking(user:, params:)
    equipment_ids = params.delete(:equipment_ids) || []
    pattern = params[:recurrence_pattern]
    end_date = params[:recurrence_end_date].to_date
    current_date = params[:start_time].to_date
    start_hour = params[:start_time]
    end_hour = params[:end_time]

    delta = case pattern
    when "daily"  then 1.day
    when "weekly" then 1.week
    when "monthly" then 1.month
    else raise StandardError, "Invalid recurrence pattern: #{pattern}"
    end

    bookings = []

    while current_date <= end_date
      instance_start = current_date.to_datetime.change(hour: start_hour.hour, min: start_hour.min)
      instance_end   = current_date.to_datetime.change(hour: end_hour.hour, min: end_hour.min)

      available, _ = ConflictDetectionService.validate_booking_times(
        venue_id: params[:venue_id],
        equipment_ids: equipment_ids,
        start_time: instance_start,
        end_time: instance_end
      )

      if available
        booking = user.bookings.build(
          venue_id: params[:venue_id],
          title: params[:title],
          description: params[:description],
          start_time: instance_start,
          end_time: instance_end,
          contact_person: params[:contact_person],
          contact_email: params[:contact_email],
          contact_phone: params[:contact_phone],
          estimated_attendance: params[:estimated_attendance],
          special_requirements: params[:special_requirements],
          is_recurring: true,
          recurrence_pattern: pattern,
          status: :pending
        )

        if equipment_ids.present?
          equipment = Equipment.where(id: equipment_ids)
          booking.equipment_list = equipment
        end

        booking.save!
        bookings << booking
      end

      current_date += delta
    end

    BookingMailer.recurring_booking_confirmation(bookings).deliver_later if bookings.any?
    bookings
  end

  def self.cancel_booking(booking:, reason: nil)
    now = Time.current
    hours_before = (booking.start_time - now) / 1.hour

    venue = booking.venue
    tenant = venue.tenant
    is_late = hours_before < tenant.cancellation_deadline_hours

    booking.update!(
      status: :cancelled,
      cancelled_at: now,
      cancellation_reason: reason
    )

    cancellation = Cancellation.create!(
      booking: booking,
      cancelled_at: now,
      hours_before_start: hours_before,
      reason: reason,
      is_late_cancellation: is_late,
      points_deducted: 0
    )

    if is_late
      user = booking.user
      points_deduction = tenant.point_deduction_per_late_cancel
      user.update!(points: user.points - points_deduction)
      cancellation.update!(points_deducted: points_deduction)

      PointDeduction.create!(
        user: user,
        booking: booking,
        points: points_deduction,
        reason: "late_cancellation"
      )
    end

    BookingMailer.booking_cancellation(booking, cancellation).deliver_later

    # Try to promote a pending booking
    promoted = promote_pending_booking(booking)

    [ cancellation, promoted ]
  end

  def self.promote_pending_booking(cancelled_booking)
    candidates = Booking.where(venue_id: cancelled_booking.venue_id, status: :pending)
                        .where.not(id: cancelled_booking.id)
                        .order(:created_at)

    candidates.each do |candidate|
      eq_ids = candidate.equipment_list.pluck(:id)
      available, _ = ConflictDetectionService.validate_booking_times(
        venue_id: candidate.venue_id,
        equipment_ids: eq_ids,
        start_time: candidate.start_time,
        end_time: candidate.end_time,
        exclude_booking_id: candidate.id
      )

      if available
        candidate.update!(status: :confirmed)
        BookingMailer.booking_confirmed_by_admin(candidate).deliver_later
        return candidate
      end
    end

    nil
  end
end
