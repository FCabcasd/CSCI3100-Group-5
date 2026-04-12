FactoryBot.define do
  factory :venue do
    tenant
    sequence(:name) { |n| "Venue #{n}" }
    description { "A test venue" }
    capacity { 50 }
    location { "Main Building" }
    latitude { 22.4196 }
    longitude { 114.2068 }
    features { { "projector" => true, "wifi" => true } }
    available_from { "08:00" }
    available_until { "22:00" }
    is_active { true }
  end
end
