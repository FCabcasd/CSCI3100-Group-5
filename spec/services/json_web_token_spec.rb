require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:user_id) { 42 }

  describe '.encode' do
    it 'generates a valid JWT token' do
      token = described_class.encode(sub: user_id)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'includes the payload in the token' do
      token = described_class.encode(sub: user_id)
      decoded = described_class.decode(token)
      expect(decoded[:sub]).to eq(user_id)
    end

    it 'sets an expiration time' do
      token = described_class.encode(sub: user_id)
      decoded = described_class.decode(token)
      expect(decoded[:exp]).to be_present
    end
  end

  describe '.encode_refresh' do
    it 'generates a refresh token with type' do
      token = described_class.encode_refresh(sub: user_id)
      decoded = described_class.decode(token)
      expect(decoded[:type]).to eq("refresh")
      expect(decoded[:sub]).to eq(user_id)
    end

    it 'has a longer expiration than access token' do
      access = described_class.encode(sub: user_id)
      refresh = described_class.encode_refresh(sub: user_id)
      access_exp = described_class.decode(access)[:exp]
      refresh_exp = described_class.decode(refresh)[:exp]
      expect(refresh_exp).to be > access_exp
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = described_class.encode(sub: user_id)
      decoded = described_class.decode(token)
      expect(decoded).to be_a(HashWithIndifferentAccess)
      expect(decoded[:sub]).to eq(user_id)
    end

    it 'returns nil for an invalid token' do
      expect(described_class.decode("invalid.token.here")).to be_nil
    end

    it 'returns nil for an expired token' do
      token = described_class.encode({ sub: user_id }, 1.second.ago)
      expect(described_class.decode(token)).to be_nil
    end

    it 'returns nil for nil input' do
      expect(described_class.decode(nil)).to be_nil
    end
  end
end
