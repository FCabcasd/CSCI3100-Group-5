require 'rails_helper'

RSpec.describe UserService do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant, is_active: true, points: 100) }

  describe '.suspend_user' do
    it 'deactivates the user' do
      described_class.suspend_user(user: user)
      expect(user.reload.is_active).to be false
    end

    it 'sets suspension_until' do
      described_class.suspend_user(user: user, hours: 48)
      expect(user.reload.suspension_until).to be_within(1.minute).of(48.hours.from_now)
    end

    it 'enqueues a suspension email' do
      expect {
        described_class.suspend_user(user: user)
      }.to have_enqueued_mail(BookingMailer, :account_suspension)
    end

    it 'returns the user' do
      result = described_class.suspend_user(user: user)
      expect(result).to eq(user)
    end
  end

  describe '.suspended?' do
    it 'returns true when suspension is active' do
      user.update!(suspension_until: 1.hour.from_now)
      expect(described_class.suspended?(user)).to be true
    end

    it 'returns false when suspension has expired' do
      user.update!(suspension_until: 1.hour.ago)
      expect(described_class.suspended?(user)).to be false
    end

    it 'returns false when no suspension' do
      expect(described_class.suspended?(user)).to be false
    end
  end
end
