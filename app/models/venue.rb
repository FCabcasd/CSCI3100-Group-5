class Venue < ApplicationRecord
  belongs_to :tenant
  has_many :bookings, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
