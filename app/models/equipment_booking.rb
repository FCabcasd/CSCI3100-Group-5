class EquipmentBooking < ApplicationRecord
  belongs_to :booking
  belongs_to :equipment
end
