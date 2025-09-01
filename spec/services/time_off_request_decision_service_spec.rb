# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeOffRequestDecisionService, type: :service do
  let(:department) { create(:department) }
  let(:admin) { create(:user, :admin, department: department) }
  let(:manager) { create(:user, :manager, department: department, manager: admin) }
  let(:employee) { create(:user, :employee, department: department, manager: manager) }
  let(:other_employee) { create(:user, :employee, department: department, manager: admin) }
  let(:time_off_type) { create(:time_off_type) }
  let(:time_off_request) do
    create(:time_off_request, user: employee, time_off_type: time_off_type, status: :pending)
  end

  describe '#call' do
    context 'when approving a request' do
      context 'with valid authorization' do
        context 'as a manager approving direct report' do
          let(:service) do
            described_class.new(
              time_off_request: time_off_request,
              approver: manager,
              decision: 'approve',
              comments: 'Enjoy your vacation!'
            )
          end

          it 'successfully approves the request' do
            result = service.call

            expect(result[:success]).to be true
            expect(result[:time_off_request].status).to eq 'approved'
            expect(result[:approval]).to be_present
          end

          it 'creates an approval record' do
            expect { service.call }.to change { Approval.count }.by(1)

            approval = Approval.last
            expect(approval.approver).to eq manager
            expect(approval.time_off_request).to eq time_off_request
            expect(approval.comments).to eq 'Enjoy your vacation!'
          end

          it 'sends notification email' do
            expect(SendTimeOffRequestStatusUpdateEmailJob).to receive(:perform_later).with(time_off_request)
            service.call
          end
        end

        context 'as an admin' do
          let(:service) do
            described_class.new(
              time_off_request: time_off_request,
              approver: admin,
              decision: 'approve'
            )
          end

          it 'successfully approves the request' do
            result = service.call

            expect(result[:success]).to be true
            expect(result[:time_off_request].status).to eq 'approved'
          end
        end
      end

      context 'with safety check in development/test' do
        let(:service) do
          described_class.new(
            time_off_request: time_off_request,
            approver: other_employee,
            decision: 'approve'
          )
        end

        it 'fails safety check with authorization error' do
          result = service.call

          expect(result[:success]).to be false
          expect(result[:error]).to include('proper authorization')
          expect(time_off_request.reload.status).to eq 'pending'
        end

        it 'does not create an approval record when safety check fails' do
          expect { service.call }.not_to change { Approval.count }
        end
      end
    end

    context 'when denying a request' do
      let(:service) do
        described_class.new(
          time_off_request: time_off_request,
          approver: manager,
          decision: 'deny',
          comments: 'Insufficient coverage during that period'
        )
      end

      it 'successfully denies the request' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:time_off_request].status).to eq 'rejected'
      end

      it 'creates an approval record with comments' do
        service.call

        approval = Approval.last
        expect(approval.comments).to eq 'Insufficient coverage during that period'
      end
    end

    context 'with invalid decision' do
      let(:service) do
        described_class.new(
          time_off_request: time_off_request,
          approver: manager,
          decision: 'invalid_decision'
        )
      end

      it 'fails with invalid decision error' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid decision')
      end
    end

    context 'with already decided request' do
      let(:approved_request) do
        create(:time_off_request, user: employee, time_off_type: time_off_type, status: :approved)
      end
      let(:service) do
        described_class.new(
          time_off_request: approved_request,
          approver: manager,
          decision: 'deny'
        )
      end

      it 'fails with invalid status error' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('already approved')
      end
    end

    context 'with different decision formats' do
      it 'accepts various approval formats' do
        %w[approve approved].each_with_index do |decision, index|
          request = create(:time_off_request,
                          user: employee,
                          status: :pending,
                          start_date: Date.today + (index * 30).days,
                          end_date: Date.today + (index * 30 + 3).days)
          service = described_class.new(
            time_off_request: request,
            approver: manager,
            decision: decision
          )

          result = service.call
          expect(result[:success]).to be true
          expect(request.reload.status).to eq 'approved'
        end
      end

      it 'accepts various denial formats' do
        %w[deny denied reject rejected].each_with_index do |decision, index|
          request = create(:time_off_request,
                          user: employee,
                          status: :pending,
                          start_date: Date.today + (index * 30 + 10).days,
                          end_date: Date.today + (index * 30 + 13).days)
          service = described_class.new(
            time_off_request: request,
            approver: manager,
            decision: decision
          )

          result = service.call
          expect(result[:success]).to be true
          expect(request.reload.status).to eq 'rejected'
        end
      end
    end

    context 'when an unexpected error occurs' do
      let(:service) do
        described_class.new(
          time_off_request: time_off_request,
          approver: manager,
          decision: 'approve'
        )
      end

      before do
        allow(time_off_request).to receive(:update!).and_raise(StandardError, 'Database error')
      end

      it 'handles the error gracefully' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq 'An unexpected error occurred'
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/TimeOffRequestDecisionService failed/)
        service.call
      end
    end
  end
end
