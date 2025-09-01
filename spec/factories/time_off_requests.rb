FactoryBot.define do
  factory :time_off_request do
    association :user
    association :time_off_type
    sequence(:start_date) { |n| Date.today + (n * 30).days }
    sequence(:end_date) { |n| Date.today + (n * 30 + 3).days }
    reason { Faker::Lorem.sentence }
    status { :pending }

    # Add a trait to automatically grant PTO to the user
    trait :with_pto do
      after(:build) do |request|
        if request.user && request.time_off_type && request.time_off_type.name == 'Vacation'
          days_needed = request.duration_in_days
          current_balance = request.user.pto_balance

          if current_balance < days_needed
            FactoryBot.create(:time_off_ledger_entry,
              user: request.user,
              amount: days_needed - current_balance + 1,
              source: request.user
            )
          end
        end
      end
    end
  end
end
