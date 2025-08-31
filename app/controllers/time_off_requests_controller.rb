class TimeOffRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_off_types, only: [:new]

  def index
    @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
  end

  def new
    # Initialize a new time off request for the form
    @time_off_request = current_user.time_off_requests.new
  end



  private

  def set_time_off_types
    @time_off_types = TimeOffType.all
  end
end
