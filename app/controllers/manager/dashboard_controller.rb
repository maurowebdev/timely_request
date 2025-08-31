class Manager::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manager

  def index
    if current_user.admin?
      # For admins, include both direct reports and their employees' requests
      managed_users = current_user.managed_employees
      second_level_users = User.where(manager: managed_users)
      all_user_ids = (managed_users.pluck(:id) + second_level_users.pluck(:id)).uniq
      all_requests = TimeOffRequest.where(user_id: all_user_ids).order(created_at: :desc)
    else
      all_requests = TimeOffRequest.where(user: current_user.managed_employees).order(created_at: :desc)
    end
    @pending_requests = all_requests.where(status: :pending)
    @approved_requests = all_requests.where(status: :approved)
    @rejected_requests = all_requests.where(status: :rejected)
  end

  private

  def authorize_manager
    redirect_to root_path, alert: "You are not authorized to view this page." unless current_user.manager? || current_user.admin?
  end
end
