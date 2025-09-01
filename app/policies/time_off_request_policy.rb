class TimeOffRequestPolicy < ApplicationPolicy
  def show?
    user.admin? || record.user == user || user.managed_employees.include?(record.user)
  end

  def create?
    true
  end

  def update?
    user.admin? || record.user == user
  end

  def approve?
    return true if user.admin?

    # Regular managers can only approve their direct reports' requests
    is_respective_manager = user.managed_employees.include?(record.user)
    is_within_manager_limit = record.duration_in_days <= TimeOffRequest::MAX_MANAGER_APPROVAL_LIMIT

    is_respective_manager && is_within_manager_limit
  end

  def deny?
    approve?
  end

  def manage?
    user.admin? || user.manager?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
