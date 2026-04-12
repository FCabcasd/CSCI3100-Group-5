FactoryBot.define do
  factory :cancellation do
    booking
    cancelled_at { Time.current }
    hours_before_start { 48.0 }
    reason { "Schedule change" }
    is_late_cancellation { false }
    points_deducted { 0 }
  end
end
