FactoryBot.define do
  factory :booking do
    user
    venue
    title { "Team Meeting" }
    description { "Weekly sync" }
    status { :pending }
    start_time { 1.day.from_now.change(hour: 10) }
    end_time { 1.day.from_now.change(hour: 12) }
    is_recurring { false }
    contact_person { "John Doe" }
    contact_email { "john@example.com" }
    contact_phone { "12345678" }
    estimated_attendance { 10 }
  end
end
