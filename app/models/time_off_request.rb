class TimeOffRequest < ApplicationRecord
  belongs_to :user
  belongs_to :time_off_type
  has_one :approval, dependent: :destroy

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :start_date, :end_date, :reason, presence: true
  validate :end_date_after_start_date
  validate :start_date_not_in_past
  validate :no_overlapping_requests

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
end
