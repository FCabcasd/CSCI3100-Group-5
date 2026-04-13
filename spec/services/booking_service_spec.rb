require 'rails_helper'

RSpec.describe BookingService do
  let(:tenant) { create(:tenant) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant, points: 100) }

  describe '.create_booking' do
    let(:params) do
      {
        venue_id: venue.id,
        title: "Team Meeting",
        description: "Weekly sync",
        start_time: 2.days.from_now.change(hour: 10),
        end_time: 2.days.from_now.change(hour: 12),
        contact_person: "John",
        contact_email: "john@example.com",
        contact_phone: "12345678",
        equipment_ids: []
      }
    end

    it 'creates a booking successfully' do
      booking = described_class.create_booking(user: user, params: params)
      expect(booking).to be_persisted
      expect(booking.status).to eq("pending")
      expect(booking.user).to eq(user)
    end

    it 'raises error when venue has conflict' do
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: params[:start_time], end_time: params[:end_time])

      expect {
        described_class.create_booking(user: user, params: params)
      }.to raise_error(StandardError, /Venue is booked/)
    end

    it 'raises error when user has insufficient points' do
      user.update!(points: 5)
      expect {
        described_class.create_booking(user: user, params: params)
      }.to raise_error(StandardError, /Insufficient points/)
    end

    it 'enqueues a confirmation email' do
      expect {
        described_class.create_booking(user: user, params: params)
      }.to have_enqueued_mail(BookingMailer, :booking_confirmation)
    end

    it 'creates a booking with equipment' do
      eq1 = create(:equipment, tenant: tenant)
      eq2 = create(:equipment, tenant: tenant)
      params[:equipment_ids] = [ eq1.id, eq2.id ]
      booking = described_class.create_booking(user: user, params: params)
      expect(booking.equipment_list.count).to eq(2)
    end

    it 'handles string time params' do
      params[:start_time] = 2.days.from_now.change(hour: 14).iso8601
      params[:end_time] = 2.days.from_now.change(hour: 16).iso8601
      booking = described_class.create_booking(user: user, params: params)
      expect(booking).to be_persisted
    end
  end

  describe '.create_recurring_booking' do
    let(:start_time) { 2.days.from_now.change(hour: 10) }
    let(:params) do
      {
        venue_id: venue.id,
        title: "Weekly Standup",
        description: "Recurring meeting",
        start_time: start_time.iso8601,
        end_time: 2.days.from_now.change(hour: 11).iso8601,
        contact_person: "Jane",
        contact_email: "jane@example.com",
        contact_phone: "87654321",
        recurrence_pattern: "weekly",
        recurrence_end_date: (start_time + 3.weeks).to_date.to_s,
        equipment_ids: []
      }
    end

    it 'creates multiple bookings for recurring pattern' do
      bookings = described_class.create_recurring_booking(user: user, params: params)
      expect(bookings.length).to be >= 2
      bookings.each do |b|
        expect(b.is_recurring).to be true
        expect(b.recurrence_pattern).to eq("weekly")
        expect(b.status).to eq("pending")
      end
    end

    it 'creates daily recurring bookings' do
      params[:recurrence_pattern] = "daily"
      params[:recurrence_end_date] = (start_time + 3.days).to_date.to_s
      bookings = described_class.create_recurring_booking(user: user, params: params)
      expect(bookings.length).to be >= 2
    end

    it 'creates monthly recurring bookings' do
      params[:recurrence_pattern] = "monthly"
      params[:recurrence_end_date] = (start_time + 3.months).to_date.to_s
      bookings = described_class.create_recurring_booking(user: user, params: params)
      expect(bookings.length).to be >= 2
    end

    it 'raises error for invalid recurrence pattern' do
      params[:recurrence_pattern] = "biweekly"
      expect {
        described_class.create_recurring_booking(user: user, params: params)
      }.to raise_error(StandardError, /Invalid recurrence pattern/)
    end

    it 'skips conflicting slots and creates the rest' do
      # Block the first slot
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: start_time, end_time: 2.days.from_now.change(hour: 11))

      bookings = described_class.create_recurring_booking(user: user, params: params)
      # Should still create bookings for weeks without conflict
      expect(bookings.length).to be >= 1
      expect(bookings.none? { |b| b.start_time.to_date == start_time.to_date }).to be true
    end

    it 'creates recurring bookings with equipment' do
      eq = create(:equipment, tenant: tenant)
      params[:equipment_ids] = [ eq.id ]
      bookings = described_class.create_recurring_booking(user: user, params: params)
      bookings.each { |b| expect(b.equipment_list.count).to eq(1) }
    end

    it 'enqueues a recurring confirmation email' do
      expect {
        described_class.create_recurring_booking(user: user, params: params)
      }.to have_enqueued_mail(BookingMailer, :recurring_booking_confirmation)
    end
  end

  describe '.cancel_booking' do
    let(:booking) do
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: 2.days.from_now.change(hour: 10),
        end_time: 2.days.from_now.change(hour: 12))
    end

    it 'cancels the booking' do
      cancellation, _ = described_class.cancel_booking(booking: booking, reason: "Changed plans")
      expect(booking.reload.status).to eq("cancelled")
      expect(cancellation.reason).to eq("Changed plans")
    end

    it 'detects late cancellation and deducts points' do
      booking.update!(start_time: 2.hours.from_now, end_time: 4.hours.from_now)
      original_points = user.points

      cancellation, _ = described_class.cancel_booking(booking: booking)
      expect(cancellation.is_late_cancellation).to be true
      expect(cancellation.points_deducted).to eq(tenant.point_deduction_per_late_cancel)
      expect(user.reload.points).to eq(original_points - tenant.point_deduction_per_late_cancel)
    end

    it 'does not deduct points for early cancellation' do
      original_points = user.points
      cancellation, _ = described_class.cancel_booking(booking: booking)
      expect(cancellation.is_late_cancellation).to be false
      expect(user.reload.points).to eq(original_points)
    end

    it 'enqueues a cancellation email' do
      expect {
        described_class.cancel_booking(booking: booking)
      }.to have_enqueued_mail(BookingMailer, :booking_cancellation)
    end

    it 'skips point deduction with admin_override' do
      booking.update!(start_time: 2.hours.from_now, end_time: 4.hours.from_now)
      original_points = user.points

      cancellation, _ = described_class.cancel_booking(booking: booking, admin_override: true)
      expect(cancellation.is_late_cancellation).to be false
      expect(user.reload.points).to eq(original_points)
    end

    it 'creates a PointDeduction record for late cancellation' do
      booking.update!(start_time: 2.hours.from_now, end_time: 4.hours.from_now)

      expect {
        described_class.cancel_booking(booking: booking)
      }.to change(PointDeduction, :count).by(1)

      pd = PointDeduction.last
      expect(pd.user).to eq(user)
      expect(pd.booking).to eq(booking)
      expect(pd.reason).to eq("late_cancellation")
    end
  end

  describe '.promote_pending_booking' do
    it 'promotes a pending booking when slot becomes available' do
      # Create and cancel a confirmed booking
      confirmed = create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: 2.days.from_now.change(hour: 10),
        end_time: 2.days.from_now.change(hour: 12))

      other_user = create(:user, tenant: tenant)
      pending_booking = create(:booking, user: other_user, venue: venue, status: :pending,
        start_time: 3.days.from_now.change(hour: 14),
        end_time: 3.days.from_now.change(hour: 16))

      promoted = described_class.promote_pending_booking(confirmed)
      expect(promoted).to eq(pending_booking)
      expect(pending_booking.reload.status).to eq("confirmed")
    end

    it 'returns nil when no pending bookings can be promoted' do
      booking = create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: 2.days.from_now.change(hour: 10),
        end_time: 2.days.from_now.change(hour: 12))
      result = described_class.promote_pending_booking(booking)
      expect(result).to be_nil
    end
  end

  describe '.broadcast_booking_event' do
    let(:booking) { create(:booking, user: user, venue: venue) }

    it 'broadcasts without error' do
      expect {
        described_class.broadcast_booking_event(booking, "booking_created")
      }.not_to raise_error
    end

    it 'handles broadcast failure gracefully' do
      allow(BookingChannel).to receive(:broadcast_to).and_raise(RuntimeError, "connection failed")
      expect {
        described_class.broadcast_booking_event(booking, "booking_created")
      }.not_to raise_error
    end
  end
end
