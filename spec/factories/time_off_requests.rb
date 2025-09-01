FactoryBot.define do
  factory :time_off_request do
    association :user
    association :time_off_type
    sequence(:start_date) { |n| Date.today + (n * 30 + 15).days } # 15+ days notice
    sequence(:end_date) { |n| Date.today + (n * 30 + 18).days } # 4 days duration
    reason { Faker::Lorem.sentence }
    status { :pending }

    # Add a trait to automatically grant PTO to the user
    trait :with_pto do
      after(:build) do |request|
        if request.user && request.time_off_type && request.time_off_type.name == "Vacation"
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

    # Trait for vacation requests (14+ days notice, max 30 days)
    trait :vacation do
      time_off_type { TimeOffType.find_by(name: "Vacation") || create(:time_off_type, name: "Vacation") }
      start_date { Date.today + 15.days }
      end_date { Date.today + 18.days } # 4 days duration
    end

    # Trait for sick leave requests (no advance notice, max 90 days)
    trait :sick_leave do
      time_off_type { TimeOffType.find_by(name: "Sick Leave") || create(:time_off_type, name: "Sick Leave") }
      start_date { Date.today }
      end_date { Date.today + 2.days } # 3 days duration
    end

    # Trait for personal day requests (3+ days notice, max 5 days)
    trait :personal_day do
      time_off_type { TimeOffType.find_by(name: "Personal Day") || create(:time_off_type, name: "Personal Day") }
      start_date { Date.today + 5.days }
      end_date { Date.today + 7.days } # 3 days duration
    end
  end
end
