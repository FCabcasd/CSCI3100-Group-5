require 'rails_helper'

RSpec.describe Cancellation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:booking) }
  end

  describe 'creation' do
    let(:cancellation) { create(:cancellation) }

    it 'persists with valid factory' do
      expect(cancellation).to be_persisted
    end

    it 'records cancelled_at timestamp' do
      expect(cancellation.cancelled_at).to be_present
    end

    it 'records hours_before_start' do
      expect(cancellation.hours_before_start).to eq(48.0)
    end

    it 'records reason' do
      expect(cancellation.reason).to eq('Schedule change')
    end
  end

  describe 'defaults' do
    let(:cancellation) { create(:cancellation) }

    it 'defaults is_late_cancellation to false' do
      expect(cancellation.is_late_cancellation).to be false
    end

    it 'defaults points_deducted to 0' do
      expect(cancellation.points_deducted).to eq(0)
    end
  end

  describe 'late cancellation' do
    let(:cancellation) { create(:cancellation, is_late_cancellation: true, points_deducted: 10, hours_before_start: 12.0) }

    it 'stores late cancellation flag' do
      expect(cancellation.is_late_cancellation).to be true
    end

    it 'stores points deducted' do
      expect(cancellation.points_deducted).to eq(10)
    end
  end
end
