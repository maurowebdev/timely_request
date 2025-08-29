class TimeOffRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_off_types, only: [:new, :create]

  def index
    @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
  end

  def new
    @time_off_request = current_user.time_off_requests.new
  end

  def create
    @time_off_request = current_user.time_off_requests.new(time_off_request_params)

    respond_to do |format|
            if @time_off_request.save
        format.turbo_stream
        format.html { redirect_to root_path, notice: 'Time off request was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_time_off_types
    @time_off_types = TimeOffType.all
  end

  def time_off_request_params
    params.require(:time_off_request).permit(:time_off_type_id, :start_date, :end_date, :reason)
  end
end
