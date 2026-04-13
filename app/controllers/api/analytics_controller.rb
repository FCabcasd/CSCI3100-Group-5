module Api
  class AnalyticsController < BaseController
    skip_before_action :authorize_request
    #before_action :require_admin!

    def booking_stats
      bookings = tenant_bookings

      render json: {
        total_bookings: bookings.count,
        pending_bookings: bookings.pending.count,
        confirmed_bookings: bookings.confirmed.count,
        cancelled_bookings: bookings.cancelled.count,
        completed_bookings: bookings.completed.count,
        no_show_bookings: bookings.no_show.count
      }
    end

    def venue_usage
      venues = Venue.where(is_active: true)

      result = venues.map do |venue|
        venue_bookings = venue.bookings

        total_hours_booked = venue_bookings.sum do |booking|
          next 0 unless booking.start_time && booking.end_time
          ((booking.end_time - booking.start_time) / 1.hour).to_f
        end

        {
          venue_id: venue.id,
          venue_name: venue.name,
          booking_count: venue_bookings.count,
          total_hours_booked: total_hours_booked.round(2)
        }
      end

      render json: result
    end

    def peak_times
      bookings = tenant_bookings.where(status: [ :pending, :confirmed, :completed ])

      hourly_counts = Hash.new(0)
      weekday_counts = Hash.new(0)

      bookings.find_each do |booking|
        next unless booking.start_time

        hourly_counts[booking.start_time.hour] += 1
        weekday_counts[booking.start_time.strftime("%A")] += 1
      end

      render json: {
        hourly_peak_times: hourly_counts.sort.map { |hour, count| { hour: hour, booking_count: count } },
        weekday_peak_times: weekday_counts.map { |day, count| { day: day, booking_count: count } }
      }
    end

    private

    def tenant_bookings
     Booking.all
    end
  end
end
