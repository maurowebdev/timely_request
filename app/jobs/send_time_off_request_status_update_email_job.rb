class SendTimeOffRequestStatusUpdateEmailJob < ApplicationJob
  queue_as :default

  def perform(time_off_request)
    TimeOffRequestMailer.status_update(time_off_request).deliver_later
  end
end
