class PointDeduction < ApplicationRecord
  belongs_to :user
  belongs_to :booking, optional: true
end
