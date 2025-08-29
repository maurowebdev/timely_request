class TimeOffRequestPolicy < ApplicationPolicy
  def show?
    user.admin? || record.user == user
  end

  def create?
    true
  end

  def update?
    user.admin? || record.user == user
  end

  def approve?
    user.admin? || user.managed_employees.include?(record.user)
  end

  def deny?
    approve?
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
