FactoryBot.define do
  factory :time_off_request do
    user { nil }
    time_off_type { nil }
    start_date { "2025-08-28" }
    end_date { "2025-08-28" }
    reason { "MyText" }
    status { 1 }
  end
end
