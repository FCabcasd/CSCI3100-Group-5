require 'rails_helper'

RSpec.describe BookingMailer, type: :mailer do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant, email: "test@example.com") }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:booking) do
    create(:booking, user: user, venue: venue, title: "Team Meeting",
           start_time: 1.day.from_now.change(hour: 10),
           end_time: 1.day.from_now.change(hour: 12))
  end

  describe '#booking_confirmation' do
    let(:mail) { described_class.booking_confirmation(booking) }

    it 'renders the headers' do
      expect(mail.subject).to include("Booking Created")
      expect(mail.to).to eq(["test@example.com"])
    end

    it 'renders the body with booking details' do
      expect(mail.body.encoded).to include("Team Meeting")
    end
  end

  describe '#booking_confirmed_by_admin' do
    let(:mail) { described_class.booking_confirmed_by_admin(booking) }

    it 'renders the headers' do
      expect(mail.subject).to include("Booking Confirmed")
      expect(mail.to).to eq(["test@example.com"])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(booking.title)
    end
  end

  describe '#booking_cancellation' do
    let(:cancellation) do
      Cancellation.create!(
        booking: booking,
        cancelled_at: Time.current,
        hours_before_start: 48,
        reason: "Changed plans",
        is_late_cancellation: false,
        points_deducted: 0
      )
    end
    let(:mail) { described_class.booking_cancellation(booking, cancellation) }

    it 'renders the headers' do
      expect(mail.subject).to include("Booking Cancelled")
      expect(mail.to).to eq(["test@example.com"])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(booking.title)
    end
  end

  describe '#recurring_booking_confirmation' do
    let(:bookings) { [booking] }
    let(:mail) { described_class.recurring_booking_confirmation(bookings) }

    it 'renders the headers' do
      expect(mail.subject).to include("Recurring Booking Created")
      expect(mail.to).to eq(["test@example.com"])
    end
  end

  describe '#account_suspension' do
    let(:mail) { described_class.account_suspension(user, "Late cancellations", 24) }

    it 'renders the headers' do
      expect(mail.subject).to include("Account Suspended")
      expect(mail.to).to eq(["test@example.com"])
    end

    it 'includes the reason' do
      expect(mail.body.encoded).to include("Late cancellations")
    end
  end
end
