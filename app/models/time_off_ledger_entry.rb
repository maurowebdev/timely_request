class TimeOffLedgerEntry < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true

  enum :entry_type, { accrual: 0, usage: 1 }
end
