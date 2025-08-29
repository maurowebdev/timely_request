class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @time_off_request = TimeOffRequest.new
    @time_off_types = TimeOffType.all
    @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
  end
end
