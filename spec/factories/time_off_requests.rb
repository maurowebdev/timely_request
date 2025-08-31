FactoryBot.define do
  factory :time_off_request do
    association :user
    association :time_off_type
    sequence(:start_date) { |n| Date.today + (n * 7).days }
    sequence(:end_date) { |n| Date.today + (n * 7 + 3).days }
    reason { Faker::Lorem.sentence }
    status { :pending }
  end
end
