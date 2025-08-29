class TimeOffRequestMailer < ApplicationMailer
  def status_update(time_off_request)
    @time_off_request = time_off_request
    @user = @time_off_request.user

    mail(
      to: @user.email,
      subject: "Your time off request has been #{@time_off_request.status}"
    )
  end
end
