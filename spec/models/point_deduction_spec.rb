require 'rails_helper'

RSpec.describe PointDeduction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:booking).optional }
  end

  describe 'creation' do
    let(:point_deduction) { create(:point_deduction) }

    it 'persists with valid factory' do
      expect(point_deduction).to be_persisted
    end

    it 'stores points value' do
      expect(point_deduction.points).to eq(10)
    end

    it 'stores reason' do
      expect(point_deduction.reason).to eq('late_cancellation')
    end
  end

  describe 'optional booking' do
    it 'can be created without a booking' do
      user = create(:user)
      deduction = PointDeduction.create!(user: user, points: 5, reason: 'manual_adjustment')
      expect(deduction.booking).to be_nil
      expect(deduction).to be_persisted
    end

    it 'can be associated with a booking' do
      booking = create(:booking)
      deduction = create(:point_deduction, user: booking.user, booking: booking)
      expect(deduction.booking).to eq(booking)
    end
  end
end
