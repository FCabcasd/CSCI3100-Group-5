require 'rails_helper'

RSpec.describe ConflictDetectionService do
  let(:tenant) { create(:tenant) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe '.check_venue_availability' do
    it 'returns true when no conflicts' do
      available, msg = described_class.check_venue_availability(
        venue_id: venue.id,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )
      expect(available).to be true
      expect(msg).to be_nil
    end

    it 'returns false when there is a time conflict' do
      create(:booking,
        user: user, venue: venue, status: :confirmed,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )

      available, msg = described_class.check_venue_availability(
        venue_id: venue.id,
        start_time: 1.day.from_now.change(hour: 11),
        end_time: 1.day.from_now.change(hour: 13)
      )
      expect(available).to be false
      expect(msg).to include("booked")
    end

    it 'ignores cancelled bookings' do
      create(:booking,
        user: user, venue: venue, status: :cancelled,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )

      available, _ = described_class.check_venue_availability(
        venue_id: venue.id,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )
      expect(available).to be true
    end

    it 'excludes the specified booking id' do
      booking = create(:booking,
        user: user, venue: venue, status: :confirmed,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )

      available, _ = described_class.check_venue_availability(
        venue_id: venue.id,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12),
        exclude_booking_id: booking.id
      )
      expect(available).to be true
    end
  end

  describe '.check_equipment_availability' do
    let(:equipment) { create(:equipment, tenant: tenant) }

    it 'returns true for available equipment' do
      available, _ = described_class.check_equipment_availability(
        equipment_id: equipment.id,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )
      expect(available).to be true
    end

    it 'returns false when equipment is booked' do
      booking = create(:booking,
        user: user, venue: venue, status: :confirmed,
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )
      EquipmentBooking.create!(booking: booking, equipment: equipment)

      available, _ = described_class.check_equipment_availability(
        equipment_id: equipment.id,
        start_time: 1.day.from_now.change(hour: 11),
        end_time: 1.day.from_now.change(hour: 13)
      )
      expect(available).to be false
    end
  end

  describe '.validate_booking_times' do
    it 'validates both venue and equipment' do
      available, _ = described_class.validate_booking_times(
        venue_id: venue.id,
        equipment_ids: [],
        start_time: 1.day.from_now.change(hour: 10),
        end_time: 1.day.from_now.change(hour: 12)
      )
      expect(available).to be true
    end
  end
end
