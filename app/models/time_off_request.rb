class TimeOffRequest < ApplicationRecord
  belongs_to :user
  belongs_to :time_off_type

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :start_date, :end_date, :reason, presence: true
  validate :end_date_after_start_date
  validate :start_date_not_in_past

  private

  def end_date_after_start_date
    return unless end_date && start_date

    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end

  def start_date_not_in_past
    return unless start_date && start_date < Date.today

    errors.add(:start_date, "cannot be in the past")
  end
end
