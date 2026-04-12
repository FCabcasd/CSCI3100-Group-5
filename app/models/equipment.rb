class Equipment < ApplicationRecord
  belongs_to :tenant
  has_many :equipment_bookings, dependent: :destroy
  has_many :bookings, through: :equipment_bookings

  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
