# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TimeOffRequest Approval Integration', type: :request do
  let(:department) { create(:department) }
  let(:admin) { create(:user, :admin, department: department) }
  let(:manager) { create(:user, :manager, department: department, manager: admin) }
  let(:employee) { create(:user, :employee, department: department, manager: manager) }
  let(:other_employee) { create(:user, :employee, department: department, manager: admin) }
  let(:time_off_type) { create(:time_off_type) }
  let(:time_off_request) do
    create(:time_off_request, user: employee, time_off_type: time_off_type, status: :pending)
  end

  # Helper to grant PTO to a user
  def grant_pto(user, amount)
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  before do
    # Grant the employee sufficient PTO for the request to be valid upon creation/approval
    grant_pto(employee, 10)
  end

  describe 'API approval workflow with Pundit + Service integration' do
    context 'when manager approves direct report request' do
      before do
        sign_in(manager, scope: :user)
        patch "/api/v1/time_off_requests/#{time_off_request.id}/approve",
              params: { comments: 'Approved for vacation' }
      end

      it 'successfully approves the request' do
        expect(response).to have_http_status(:ok)
        expect(time_off_request.reload.status).to eq('approved')
      end

      it 'creates approval audit record' do
        approval = time_off_request.reload.approval
        expect(approval).to be_present
        expect(approval.approver).to eq(manager)
        expect(approval.comments).to eq('Approved for vacation')
      end

      it 'returns proper JSON response' do
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['status']).to eq('approved')
      end
    end

    context 'when admin approves any request' do
      before do
        sign_in(admin, scope: :user)
        patch "/api/v1/time_off_requests/#{time_off_request.id}/approve"
      end

      it 'successfully approves the request' do
        expect(response).to have_http_status(:ok)
        expect(time_off_request.reload.status).to eq('approved')
      end
    end

    context 'when unauthorized user tries to approve' do
      before do
        sign_in(other_employee, scope: :user)
        patch "/api/v1/time_off_requests/#{time_off_request.id}/approve"
      end

      it 'is blocked by Pundit before reaching service' do
        expect(response).to have_http_status(:forbidden)
        expect(time_off_request.reload.status).to eq('pending')
      end

      it 'does not create approval record' do
        expect(time_off_request.reload.approval).to be_nil
      end
    end

    context 'when trying to approve already approved request' do
      let(:approved_request) do
        create(:time_off_request, user: employee, time_off_type: time_off_type, status: :approved)
      end

      before do
        approved_request.create_approval!(approver: manager, comments: 'Already approved')
        sign_in(manager, scope: :user)
        patch "/api/v1/time_off_requests/#{approved_request.id}/approve"
      end

      it 'passes Pundit authorization but fails in service logic' do
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(/already approved/)
      end
    end
  end

  describe 'Email notification integration' do
    before do
      sign_in(manager, scope: :user)
    end

    it 'triggers email job when request is approved' do
      expect(SendTimeOffRequestStatusUpdateEmailJob).to receive(:perform_later).with(time_off_request)
      patch "/api/v1/time_off_requests/#{time_off_request.id}/approve"
    end

    it 'triggers email job when request is denied' do
      expect(SendTimeOffRequestStatusUpdateEmailJob).to receive(:perform_later).with(time_off_request)
      patch "/api/v1/time_off_requests/#{time_off_request.id}/deny",
            params: { comments: 'Insufficient coverage' }
    end
  end

  describe 'Audit trail verification' do
    context 'after approval' do
      before do
        sign_in(manager, scope: :user)
        patch "/api/v1/time_off_requests/#{time_off_request.id}/approve",
              params: { comments: 'Vacation approved' }
      end

      it 'maintains complete audit trail' do
        time_off_request.reload
        approval = time_off_request.approval

        expect(time_off_request.status).to eq('approved')
        expect(approval).to be_present
        expect(approval.approver).to eq(manager)
        expect(approval.comments).to eq('Vacation approved')
        expect(approval.created_at).to be_within(1.second).of(Time.current)
        expect(manager.approvals).to include(approval)
        expect(time_off_request.approval).to eq(approval)
      end
    end
  end
end
