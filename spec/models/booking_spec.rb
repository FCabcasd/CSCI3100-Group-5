require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:venue) }
    it { should have_many(:equipment_bookings).dependent(:destroy) }
    it { should have_many(:equipment_list).through(:equipment_bookings) }
    it { should have_one(:cancellation).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }

    it 'validates end_time is after start_time' do
      booking = build(:booking, start_time: 1.day.from_now, end_time: 1.day.ago)
      expect(booking).not_to be_valid
      expect(booking.errors[:end_time]).to include('must be after start_time')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, completed: 3, no_show: 4) }
  end

  describe 'scopes' do
    it '.active returns pending and confirmed bookings' do
      pending_b = create(:booking, status: :pending)
      confirmed_b = create(:booking, status: :confirmed)
      create(:booking, status: :cancelled)
      expect(Booking.active).to contain_exactly(pending_b, confirmed_b)
    end
  end
end
