FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :employee }
    department
    manager { nil }

    trait :admin do
      role { :admin }
    end

    trait :manager do
      role { :manager }
    end

    trait :employee do
      role { :employee }
    end
  end
end
