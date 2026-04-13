require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(sub: user.id) }

  it "connects with a valid token" do
    connect "/cable?token=#{token}"
    expect(connection.current_user).to eq(user)
  end

  it "rejects connection without a token" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects connection with an invalid token" do
    expect { connect "/cable?token=invalid" }.to have_rejected_connection
  end

  it "rejects connection with a refresh token" do
    refresh_token = JsonWebToken.encode_refresh(sub: user.id)
    expect { connect "/cable?token=#{refresh_token}" }.to have_rejected_connection
  end

  it "rejects connection for inactive user" do
    user.update!(is_active: false)
    expect { connect "/cable?token=#{token}" }.to have_rejected_connection
  end
end
