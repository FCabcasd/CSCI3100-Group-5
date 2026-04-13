module Api
  class BookingsController < BaseController
    def create
      booking = BookingService.create_booking(
        user: @current_user,
        params: booking_params.to_h.symbolize_keys
      )
      render json: booking_response(booking), status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :bad_request
    end

    def index
      bookings = if @current_user.admin?
                   Booking.all
                 elsif @current_user.tenant_admin?
                   tenant_venue_ids = Venue.where(tenant_id: @current_user.tenant_id).pluck(:id)
                   tenant_equip_ids = Equipment.where(tenant_id: @current_user.tenant_id).pluck(:id)
                   booking_ids_from_equip = EquipmentBooking.where(equipment_id: tenant_equip_ids).pluck(:booking_id)
                   Booking.where(venue_id: tenant_venue_ids)
                          .or(Booking.where(id: booking_ids_from_equip))
                          .or(Booking.where(user_id: @current_user.id))
                 else
                   @current_user.bookings
                 end
      bookings = bookings.includes(:venue, :user, :equipment_list)
                         .order(created_at: :desc)
                         .offset(params[:skip].to_i)
                         .limit([ params.fetch(:limit, 10).to_i, 100 ].min)
      render json: bookings.map { |b| booking_detail_response(b) }
    end

    def show
      booking = Booking.includes(:venue, :user, :equipment_list).find(params[:id])

      unless booking.user_id == @current_user.id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      render json: booking_detail_response(booking)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    def cancel
      booking = Booking.find(params[:id])

      unless booking.user_id == @current_user.id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      if booking.cancelled?
        return render json: { error: "Booking already cancelled" }, status: :bad_request
      end

      cancellation, promoted = BookingService.cancel_booking(
        booking: booking,
        reason: params[:reason]
      )

      render json: {
        success: true,
        message: "Booking cancelled",
        cancelled_booking_id: booking.id,
        cancellation: cancellation_response(cancellation),
        promoted_booking: promoted ? booking_response(promoted) : nil
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    def confirm
      unless @current_user.admin? || @current_user.tenant_admin?
        return render json: { error: "Only admins can confirm bookings" }, status: :forbidden
      end

      booking = Booking.find(params[:id])

      unless booking.pending?
        return render json: { error: "Only pending bookings can be confirmed" }, status: :bad_request
      end

      booking.update!(status: :confirmed)
      BookingMailer.booking_confirmed_by_admin(booking).deliver_later
      BookingService.broadcast_booking_event(booking, "booking_confirmed")

      render json: { success: true, message: "Booking confirmed", booking: booking_response(booking) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    def reject
      unless @current_user.admin? || @current_user.tenant_admin?
        return render json: { error: "Only admins can reject bookings" }, status: :forbidden
      end

      booking = Booking.find(params[:id])

      unless booking.pending?
        return render json: { error: "Only pending bookings can be rejected" }, status: :bad_request
      end

      booking.update!(status: :rejected)
      BookingService.broadcast_booking_event(booking, "booking_rejected")

      render json: { success: true, message: "Booking rejected", booking: booking_response(booking) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    def check_in
      booking = Booking.find(params[:id])

      unless booking.user_id == @current_user.id || @current_user.admin? || @current_user.tenant_admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      unless booking.confirmed?
        return render json: { error: "Only confirmed bookings can be checked in" }, status: :bad_request
      end

      if booking.checked_in_at.present?
        return render json: { error: "Already checked in" }, status: :bad_request
      end

      booking.update!(checked_in_at: Time.current)
      BookingService.broadcast_booking_event(booking, "booking_checked_in")

      render json: { success: true, message: "Checked in successfully", booking: booking_response(booking).merge(checked_in_at: booking.checked_in_at) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    def create_recurring
      bookings = BookingService.create_recurring_booking(
        user: @current_user,
        params: recurring_booking_params.to_h.symbolize_keys
      )
      render json: bookings.map { |b| booking_response(b) }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :bad_request
    end

    private

    def booking_params
      params.permit(
        :title, :description, :venue_id, :start_time, :end_time,
        :contact_person, :contact_email, :contact_phone,
        :estimated_attendance, :special_requirements,
        equipment_ids: []
      )
    end

    def recurring_booking_params
      params.permit(
        :title, :description, :venue_id, :start_time, :end_time,
        :contact_person, :contact_email, :contact_phone,
        :estimated_attendance, :special_requirements,
        :recurrence_pattern, :recurrence_end_date,
        equipment_ids: []
      )
    end

    def booking_response(booking)
      {
        id: booking.id,
        user_id: booking.user_id,
        venue_id: booking.venue_id,
        title: booking.title,
        description: booking.description,
        status: booking.status,
        start_time: booking.start_time,
        end_time: booking.end_time,
        is_recurring: booking.is_recurring,
        recurrence_pattern: booking.recurrence_pattern,
        contact_person: booking.contact_person,
        contact_email: booking.contact_email,
        contact_phone: booking.contact_phone,
        created_at: booking.created_at,
        updated_at: booking.updated_at
      }
    end

    def booking_detail_response(booking)
      booking_response(booking).merge(
        venue: booking.venue ? venue_response(booking.venue) : nil,
        user: { id: booking.user.id, email: booking.user.email, username: booking.user.username },
        equipment_list: booking.equipment_list.map { |e| equipment_response(e) }
      )
    end

    def venue_response(venue)
      {
        id: venue.id, name: venue.name, capacity: venue.capacity,
        location: venue.location, tenant_id: venue.tenant_id
      }
    end

    def equipment_response(eq)
      {
        id: eq.id, name: eq.name, description: eq.description,
        quantity: eq.quantity, equipment_type: eq.equipment_type, tenant_id: eq.tenant_id
      }
    end

    def cancellation_response(c)
      {
        id: c.id, booking_id: c.booking_id, cancelled_at: c.cancelled_at,
        hours_before_start: c.hours_before_start,
        is_late_cancellation: c.is_late_cancellation,
        points_deducted: c.points_deducted
      }
    end
  end
end
