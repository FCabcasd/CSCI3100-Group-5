class BookingMailer < ApplicationMailer
  default from: ENV.fetch("SMTP_FROM", "noreply@cuhkbooking.com")

  def booking_confirmation(booking)
    @booking = booking
    @user = booking.user
    @venue = booking.venue
    mail(to: @user.email, subject: "Booking Created - #{@booking.title}")
  end

  def booking_confirmed_by_admin(booking)
    @booking = booking
    @user = booking.user
    @venue = booking.venue
    mail(to: @user.email, subject: "Booking Confirmed - #{@booking.title}")
  end

  def booking_cancellation(booking, cancellation)
    @booking = booking
    @cancellation = cancellation
    @user = booking.user
    @venue = booking.venue
    mail(to: @user.email, subject: "Booking Cancelled - #{@booking.title}")
  end

  def recurring_booking_confirmation(bookings)
    @bookings = bookings
    @user = bookings.first.user
    @venue = bookings.first.venue
    @count = bookings.size
    mail(to: @user.email, subject: "Recurring Booking Created - #{bookings.first.title} (#{@count} bookings)")
  end

  def account_suspension(user, reason, hours)
    @user = user
    @reason = reason
    @hours = hours
    mail(to: @user.email, subject: "Account Suspended - Action Required")
  end
end
