require 'rails_helper'

RSpec.describe Tenant, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:venues).dependent(:destroy) }
    it { should have_many(:equipment).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:tenant) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_numericality_of(:cancellation_deadline_hours).is_greater_than(0) }
    it { should validate_numericality_of(:point_deduction_per_late_cancel).is_greater_than(0) }
  end

  describe 'defaults' do
    let(:tenant) { create(:tenant) }

    it 'has default values' do
      expect(tenant.is_active).to be true
      expect(tenant.cancellation_deadline_hours).to eq(24)
      expect(tenant.point_deduction_per_late_cancel).to eq(10)
      expect(tenant.max_recurring_days).to eq(180)
    end
  end
end
