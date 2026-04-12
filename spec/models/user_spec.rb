require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant).optional }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:point_deductions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:user) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }
    it { should validate_presence_of(:hashed_password) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(user: 0, tenant_admin: 1, admin: 2) }
  end

  describe '#password=' do
    it 'hashes the password with bcrypt' do
      user = build(:user)
      user.password = 'newpassword'
      expect(BCrypt::Password.new(user.hashed_password).is_password?('newpassword')).to be true
    end
  end

  describe '#authenticate' do
    it 'returns true for correct password' do
      user = create(:user)
      user.password = 'testpass'
      user.save!
      expect(user.authenticate('testpass')).to be true
    end

    it 'returns false for wrong password' do
      user = create(:user)
      user.password = 'testpass'
      user.save!
      expect(user.authenticate('wrong')).to be false
    end
  end

  describe '#suspended?' do
    it 'returns true when suspension is in the future' do
      user = create(:user, suspension_until: 1.day.from_now)
      expect(user.suspended?).to be true
    end

    it 'returns false when suspension is in the past' do
      user = create(:user, suspension_until: 1.day.ago)
      expect(user.suspended?).to be false
    end

    it 'returns false when no suspension' do
      user = create(:user, suspension_until: nil)
      expect(user.suspended?).to be false
    end
  end
end
