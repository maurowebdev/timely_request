class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  belongs_to :department
  belongs_to :manager, class_name: "User", optional: true # A user can have a manager

  has_many :managed_employees, class_name: "User", foreign_key: "manager_id", dependent: :nullify # A manager can have many employees
  has_many :time_off_requests

  enum role: { employee: 0, manager: 1, admin: 2 }
end
