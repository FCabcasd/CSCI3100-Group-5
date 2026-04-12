require 'rails_helper'

RSpec.describe Venue, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_many(:bookings).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'scopes' do
    it '.active returns only active venues' do
      active = create(:venue, is_active: true)
      create(:venue, is_active: false)
      expect(Venue.active).to eq([ active ])
    end
  end
end
