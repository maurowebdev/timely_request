# frozen_string_literal: true

# Service object for handling time-off request approval/denial decisions
#
# Usage:
#   # Approve a request
#   result = TimeOffRequestDecisionService.new(
#     time_off_request: request,
#     approver: current_user,
#     decision: 'approve',
#     comments: 'Enjoy your vacation!'
#   ).call
#
#   if result[:success]
#     # Handle success
#     approved_request = result[:time_off_request]
#     approval_record = result[:approval]
#   else
#     # Handle error
#     error_message = result[:error]
#   end
#
# Features:
# - Status validation (can't approve already decided requests)
# - Audit trail creation with approval records
# - Email notifications via background jobs
# - Transaction safety (rollback on errors)
# - Flexible decision formats ('approve', 'approved', 'deny', 'denied', etc.)
#
# Note: Authorization should be handled by the controller using Pundit before calling this service.
# This service includes an optional safety check but relies on proper controller authorization.
#
class TimeOffRequestDecisionService
  class Error < StandardError; end
  class InvalidStatusError < Error; end
  class AuthorizationError < Error; end

  attr_reader :time_off_request, :approver, :decision, :comments

  def initialize(time_off_request:, approver:, decision:, comments: nil)
    @time_off_request = time_off_request
    @approver = approver
    @decision = decision.to_s.downcase
    @comments = comments
  end

  def call
    validate_decision!
    validate_request_status!
    safety_check_authorization! if Rails.env.development? || Rails.env.test?

    ActiveRecord::Base.transaction do
      update_request_status!
      create_approval_record!
      send_notification!
    end

    { success: true, time_off_request: time_off_request, approval: time_off_request.approval }
  rescue Error => e
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "TimeOffRequestDecisionService failed: #{e.message}"
    { success: false, error: "An unexpected error occurred" }
  end

  private

  def validate_decision!
    unless %w[approve approved deny denied reject rejected].include?(decision)
      raise Error, "Invalid decision: #{decision}. Must be 'approve' or 'deny'"
    end
  end

  # Safety check - should not be relied upon as primary authorization
  # Primary authorization should happen in controller via Pundit
  def safety_check_authorization!
    return true if approver.admin?
    return true if approver.manager? && approver.managed_employees.include?(time_off_request.user)

    Rails.logger.warn "TimeOffRequestDecisionService: Authorization safety check failed for user #{approver.id}"
    raise AuthorizationError, "Service called without proper authorization"
  end

  def validate_request_status!
    unless time_off_request.pending?
      raise InvalidStatusError, "Cannot #{decision} a request that is already #{time_off_request.status}"
    end
  end

  def update_request_status!
    new_status = approved_decision? ? :approved : :rejected
    time_off_request.update!(status: new_status)
  end

  def create_approval_record!
    time_off_request.create_approval!(
      approver: approver,
      comments: comments
    )
  end

  def send_notification!
    SendTimeOffRequestStatusUpdateEmailJob.perform_later(time_off_request)
  end

  def approved_decision?
    %w[approve approved].include?(decision)
  end
end
