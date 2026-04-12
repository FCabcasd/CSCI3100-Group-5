class User < ApplicationRecord
  belongs_to :tenant, optional: true
  has_many :bookings, dependent: :destroy
  has_many :point_deductions, dependent: :destroy

  enum :role, { user: 0, tenant_admin: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :hashed_password, presence: true

  def password=(raw_password)
    self.hashed_password = BCrypt::Password.create(raw_password)
  end

  def authenticate(raw_password)
    BCrypt::Password.new(hashed_password).is_password?(raw_password)
  end

  def suspended?
    suspension_until.present? && Time.current < suspension_until
  end
end
