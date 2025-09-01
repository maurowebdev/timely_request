class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  belongs_to :department
  belongs_to :manager, class_name: "User", optional: true # A user can have a manager

  has_many :managed_employees, class_name: "User", foreign_key: "manager_id", dependent: :nullify # A manager can have many employees
  has_many :time_off_requests
  has_many :time_off_ledger_entries

  enum :role, { employee: 0, manager: 1, admin: 2 }

  validate :cannot_be_own_manager
  validate :no_circular_references

  def pto_balance
    time_off_ledger_entries.sum(:amount).ceil
  end

  private

  def cannot_be_own_manager
    errors.add(:manager, "can't be yourself") if manager == self
  end

  def no_circular_references
    return unless manager

    current_manager = manager
    while current_manager
      if current_manager == self
        errors.add(:manager_id, "creates a circular reference")
        break
      end
      current_manager = current_manager.manager
    end
  end
end
