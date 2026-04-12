class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :venue
  has_many :equipment_bookings, dependent: :destroy
  has_many :equipment_list, through: :equipment_bookings, source: :equipment
  has_one :cancellation, dependent: :destroy
  belongs_to :parent_booking, class_name: "Booking", optional: true
  has_many :child_bookings, class_name: "Booking", foreign_key: :parent_booking_id

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3, no_show: 4 }

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  scope :active, -> { where(status: [ :pending, :confirmed ]) }

  private

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "must be after start_time") if end_time <= start_time
  end
end
