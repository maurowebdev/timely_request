FactoryBot.define do
  factory :time_off_request do
    association :user
    association :time_off_type
    start_date { Date.today + 7.days }
    end_date { Date.today + 10.days }
    reason { Faker::Lorem.sentence }
    status { :pending }
  end
end
