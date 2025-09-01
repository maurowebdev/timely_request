class TimeOffRequest < ApplicationRecord
  belongs_to :user
  belongs_to :time_off_type
  has_one :approval, dependent: :destroy

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :start_date, :end_date, :reason, presence: true
  validate :end_date_after_start_date
  validate :start_date_not_in_past
  validate :no_overlapping_requests
  validate :sufficient_pto_balance, on: :create
  validate :advance_notice_requirement
  validate :max_consecutive_days_limit

  def duration_in_days
    return 0 if start_date.nil? || end_date.nil?

    (end_date - start_date).to_i + 1
  end

  private

  def end_date_after_start_date
    return unless end_date && start_date

    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def start_date_not_in_past
    return unless start_date && start_date < Date.today

    errors.add(:start_date, "cannot be in the past")
  end

  def no_overlapping_requests
    return unless user && start_date && end_date

    overlapping_requests = user.time_off_requests.where.not(id: id).where("start_date <= ? AND end_date >= ?", end_date, start_date)

    errors.add(:base, "#{overlapping_requests.count} overlapping requests found: #{overlapping_requests.map { |request| [ request.id, request.start_date, request.end_date ] }.join(', ')}") if overlapping_requests.any?
  end

  def sufficient_pto_balance
    return if time_off_type&.name != "Vacation"
    return unless user && start_date && end_date

    if user.pto_balance < duration_in_days
      errors.add(:base, "You do not have enough PTO for this request. Current balance: #{user.pto_balance} days.")
    end
  end

  def advance_notice_requirement
    return unless time_off_type && start_date

    required_days = time_off_type.advance_notice_days
    return if required_days == 0

    days_until_start = (start_date - Date.current).to_i
    if days_until_start < required_days
      errors.add(:start_date, "requires #{required_days} days advance notice for #{time_off_type.name}")
    end
  end

  def max_consecutive_days_limit
    return unless time_off_type && start_date && end_date

    max_days = time_off_type.max_consecutive_days
    request_days = duration_in_days

    if request_days > max_days
      errors.add(:end_date, "cannot exceed #{max_days} consecutive days for #{time_off_type.name}")
    end
  end
end
