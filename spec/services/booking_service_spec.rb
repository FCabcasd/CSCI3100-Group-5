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
  end
end
