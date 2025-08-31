class Manager::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manager
  before_action :set_time_off_request, only: %i[approve deny]

  def index
    @pending_requests = TimeOffRequest.where(user: current_user.managed_employees, status: :pending).order(created_at: :desc)
    @approved_requests = TimeOffRequest.where(user: current_user.managed_employees, status: :approved).order(created_at: :desc)
    @rejected_requests = TimeOffRequest.where(user: current_user.managed_employees, status: :rejected).order(created_at: :desc)
  end

  def approve
    authorize @time_off_request, :approve?

    result = TimeOffRequestDecisionService.new(
      time_off_request: @time_off_request,
      approver: current_user,
      decision: 'approve',
      comments: params[:comments]
    ).call

    if result[:success]
      @approved_requests = TimeOffRequest.where(user: current_user.managed_employees, status: :approved).order(created_at: :desc)
      respond_to do |format|
        format.turbo_stream
      end
    else
      redirect_to manager_root_path, alert: result[:error]
    end
  end

  def deny
    authorize @time_off_request, :deny?

    result = TimeOffRequestDecisionService.new(
      time_off_request: @time_off_request,
      approver: current_user,
      decision: 'deny',
      comments: params[:comments]
    ).call

    if result[:success]
      @rejected_requests = TimeOffRequest.where(user: current_user.managed_employees, status: :rejected).order(created_at: :desc)
      respond_to do |format|
        format.turbo_stream
      end
    else
      redirect_to manager_root_path, alert: result[:error]
    end
  end

  private

  def set_time_off_request
    @time_off_request = TimeOffRequest.find(params[:id])
  end

  def authorize_manager
    redirect_to root_path, alert: "You are not authorized to view this page." unless current_user.manager? || current_user.admin?
  end
end
