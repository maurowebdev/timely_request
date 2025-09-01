class MonthlyPtoAccrualJob < ApplicationJob
  queue_as :default

  ACCRUAL_AMOUNT = 1.0 # 1 day

  def perform
    User.find_each do |user|
      TimeOffLedgerEntry.create!(
        user: user,
        entry_type: :accrual,
        amount: ACCRUAL_AMOUNT,
        effective_date: Date.current,
        notes: "Monthly PTO accrual for #{Date.current.strftime('%B %Y')}",
        source: user
      )
    end
  end
end
