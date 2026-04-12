FactoryBot.define do
  factory :equipment do
    tenant
    sequence(:name) { |n| "Equipment #{n}" }
    description { "Test equipment" }
    quantity { 5 }
    equipment_type { "projector" }
    status { "available" }
    is_active { true }
  end
end
