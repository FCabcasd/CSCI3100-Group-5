require 'rails_helper'

RSpec.describe Equipment, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_many(:equipment_bookings).dependent(:destroy) }
    it { should have_many(:bookings).through(:equipment_bookings) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'scopes' do
    it '.active returns only active equipment' do
      active = create(:equipment, is_active: true)
      create(:equipment, is_active: false)
      expect(Equipment.active).to eq([ active ])
    end
  end
end
