FactoryBot.define do
  factory :time_off_ledger_entry do
    user { nil }
    entry_type { 1 }
    amount { "9.99" }
    effective_date { "2025-08-31" }
    notes { "MyText" }
    source { nil }
  end
end
