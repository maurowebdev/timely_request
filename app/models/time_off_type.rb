class TimeOffType < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  # Business rules for different time-off types
  def requires_advance_notice?
    name == "Vacation"
  end

  def advance_notice_days
    case name
    when "Vacation"
      14 # 2 weeks notice for vacation
    when "Sick Leave"
      0 # No advance notice for sick leave
    when "Personal Day"
      3 # 3 days notice for personal days
    else
      7 # Default 1 week notice
    end
  end

  def max_consecutive_days
    case name
    when "Vacation"
      30 # Max 30 consecutive vacation days
    when "Sick Leave"
      90 # Max 90 consecutive sick days
    when "Personal Day"
      5 # Max 5 consecutive personal days
    else
      14 # Default 2 weeks
    end
  end

  def requires_manager_approval?
    name != "Sick Leave" # Sick leave is typically auto-approved
  end
end
