class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :equipment, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :cancellation_deadline_hours, numericality: { greater_than: 0 }
  validates :point_deduction_per_late_cancel, numericality: { greater_than: 0 }
  validates :max_recurring_days, numericality: { greater_than: 0 }
end
