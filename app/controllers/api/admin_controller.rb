module Api
  class AdminController < BaseController
    before_action :require_admin!

    def users
      scope = User.where(is_active: true)
      if params[:role].present?
        roles = Array(params[:role])
        scope = scope.where(role: roles.map { |r| User.roles[r] }.compact)
      end
      scope = scope.offset(params[:skip].to_i)

      render json: scope.map { |u| user_response(u) }
    end

    def suspend_user
      user = User.find(params[:id])
      UserService.suspend_user(user: user)
      render json: user_response(user)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    def delete_user
      user = User.find(params[:id])
      user.update!(is_active: false)
      render json: { success: true, message: "User deleted" }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    def force_cancel
      booking = Booking.find(params[:id])

      if booking.cancelled?
        return render json: { error: "Booking already cancelled" }, status: :bad_request
      end

      cancellation, promoted = BookingService.cancel_booking(
        booking: booking,
        reason: params[:reason] || "Admin emergency cancellation",
        admin_override: true
      )

      broadcast_admin_cancel(booking)

      render json: {
        success: true,
        message: "Booking force-cancelled without point penalty",
        cancelled_booking_id: booking.id,
        cancellation: cancellation_response(cancellation),
        promoted_booking: promoted ? { id: promoted.id, title: promoted.title, status: promoted.status } : nil
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Booking not found" }, status: :not_found
    end

    private

    def user_response(user)
      {
        id: user.id,
        email: user.email,
        username: user.username,
        full_name: user.full_name,
        role: user.role,
        tenant_id: user.tenant_id,
        is_active: user.is_active,
        points: user.points,
        created_at: user.created_at
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

    def broadcast_admin_cancel(booking)
      BookingChannel.broadcast_to(
        booking.user,
        {
          type: "booking_force_cancelled",
          booking: { id: booking.id, title: booking.title, status: booking.status },
          message: "Your booking has been cancelled by an administrator",
          timestamp: Time.current.iso8601
        }
      )
    rescue => e
      Rails.logger.warn("ActionCable broadcast failed: #{e.message}")
    end
  end
end
