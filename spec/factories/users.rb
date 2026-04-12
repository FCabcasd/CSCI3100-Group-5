FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    full_name { "Test User" }
    hashed_password { BCrypt::Password.create("password123") }
    role { :user }
    tenant
    is_active { true }
    points { 100 }
    suspension_until { nil }

    trait :admin do
      role { :admin }
    end

    trait :tenant_admin do
      role { :tenant_admin }
    end
  end
end
