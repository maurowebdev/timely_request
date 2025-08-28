class TimeOffRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_off_types, only: [:new, :create]

  def index
    @time_off_requests = current_user.time_off_requests.order(created_at: :desc)
  end

  def new
  end

  def create
  end

  def index
  end
end
