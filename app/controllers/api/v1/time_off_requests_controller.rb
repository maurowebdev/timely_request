class Api::V1::TimeOffRequestsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_time_off_request, except: %i[index create manager_dashboard]
  def index
    if current_user.manager? || current_user.admin?
      # For managers and admins, show requests from their managed employees
      @time_off_requests = TimeOffRequest.where(user: current_user.managed_employees).order(created_at: :desc)
    else
      # For regular users, show only their own requests
      @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
    end
    render json: TimeOffRequestSerializer.new(@time_off_requests).serializable_hash
  end

  def manager_dashboard
    authorize :time_off_request, :manage?

    if current_user.admin?
      managed_users = current_user.managed_employees
      second_level_users = User.where(manager: managed_users)
      all_user_ids = (managed_users.pluck(:id) + second_level_users.pluck(:id)).uniq
      @time_off_requests = TimeOffRequest.where(user_id: all_user_ids).order(created_at: :desc)
    else
      @time_off_requests = TimeOffRequest.where(user: current_user.managed_employees).order(created_at: :desc)
    end

    render json: TimeOffRequestSerializer.new(@time_off_requests).serializable_hash
  end

  def show
    authorize @time_off_request
    render json: TimeOffRequestSerializer.new(@time_off_request).serializable_hash
  end

  def create
    @time_off_request = current_user.time_off_requests.new(time_off_request_params)
    authorize @time_off_request

    if @time_off_request.save
      render json: TimeOffRequestSerializer.new(@time_off_request).serializable_hash, status: :created
    else
      render json: { errors: @time_off_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @time_off_request
    if @time_off_request.update(time_off_request_params)
      render json: TimeOffRequestSerializer.new(@time_off_request).serializable_hash
    else
      render json: { errors: @time_off_request.errors.full_messages }, status: :unprocessable_entity
    end
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
      render json: TimeOffRequestSerializer.new(result[:time_off_request]).serializable_hash
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
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
      render json: TimeOffRequestSerializer.new(result[:time_off_request]).serializable_hash
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  end

  private

  def set_time_off_request
    @time_off_request = TimeOffRequest.find(params[:id])
  end

  def time_off_request_params
    params.require(:time_off_request).permit(:time_off_type_id, :start_date, :end_date, :reason)
  end
end
