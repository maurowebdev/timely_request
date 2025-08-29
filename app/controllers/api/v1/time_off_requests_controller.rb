class Api::V1::TimeOffRequestsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_time_off_request, except: %i[index create]
  def index
    @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
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
    authorize @time_off_request
    @time_off_request.approved!
    SendTimeOffRequestStatusUpdateEmailJob.perform_later(@time_off_request)
    render json: TimeOffRequestSerializer.new(@time_off_request).serializable_hash
  end

  def deny
    authorize @time_off_request
    @time_off_request.rejected!
    SendTimeOffRequestStatusUpdateEmailJob.perform_later(@time_off_request)
    render json: TimeOffRequestSerializer.new(@time_off_request).serializable_hash
  end

  private

  def set_time_off_request
    @time_off_request = TimeOffRequest.find(params[:id])
  end

  def time_off_request_params
    params.require(:time_off_request).permit(:time_off_type_id, :start_date, :end_date, :reason)
  end
end
