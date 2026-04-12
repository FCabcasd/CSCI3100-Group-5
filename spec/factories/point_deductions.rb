FactoryBot.define do
  factory :point_deduction do
    user
    booking { nil }
    points { 10 }
    reason { "late_cancellation" }
  end
end
