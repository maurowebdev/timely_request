FactoryBot.define do
  factory :approval do
    time_off_request { nil }
    approver { nil }
    action { 1 }
    comments { "MyText" }
    decided_at { "2025-08-31 10:03:44" }
  end
end
