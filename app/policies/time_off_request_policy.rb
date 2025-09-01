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
    user.managed_employees.include?(record.user)
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
