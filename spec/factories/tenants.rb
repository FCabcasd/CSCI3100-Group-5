FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "Department #{n}" }
    description { "Test department" }
    is_active { true }
    cancellation_deadline_hours { 24 }
    point_deduction_per_late_cancel { 10 }
    max_recurring_days { 180 }
  end
end
