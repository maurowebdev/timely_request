require 'rails_helper'

RSpec.describe "Api::V1::TimeOffRequests", type: :request do
  # Create test users with appropriate roles
  let(:department) { create(:department) }
  let(:admin) { create(:user, :admin, :with_pto, department: department) }
  let(:manager) { create(:user, :manager, :with_pto, department: department, manager: admin) }
  let(:employee) { create(:user, :employee, :with_pto, department: department, manager: manager) }
  let(:other_employee) { create(:user, :employee, :with_pto, department: department, manager: manager) }
  let(:unrelated_employee) { create(:user, :employee, :with_pto, department: department) }

  # Create a time_off_type for testing
  let(:time_off_type) { TimeOffType.find_by(name: "Vacation") || create(:time_off_type, name: "Vacation") }

  # Helper method to grant PTO to a user
  def grant_pto(user, amount)
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  # Create time off requests for testing
  let!(:employee_request) do
    grant_pto(employee, 10)
    create(:time_off_request, :vacation, user: employee)
  end

  let!(:other_employee_request) do
    grant_pto(other_employee, 10)
    create(:time_off_request, :vacation, user: other_employee)
  end

  let!(:unrelated_request) do
    grant_pto(unrelated_employee, 10)
    create(:time_off_request, :vacation, user: unrelated_employee)
  end

  describe "GET /api/v1/time_off_requests" do
    context "as an employee" do
      before do
        login_as(employee, scope: :user)
        get "/api/v1/time_off_requests"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns only their own time off requests" do
        json_response = JSON.parse(response.body)
        request_ids = json_response['data'].map { |r| r['id'].to_i }
        expect(request_ids).to contain_exactly(employee_request.id)
      end
    end

    context "as a manager" do
      before do
        login_as(manager, scope: :user)
        get "/api/v1/time_off_requests"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns requests for their direct reports" do
        json_response = JSON.parse(response.body)
        request_ids = json_response['data'].map { |r| r['id'].to_i }
        expect(request_ids).to contain_exactly(employee_request.id, other_employee_request.id)
      end
    end

    context "as an admin" do
      before do
        login_as(admin, scope: :user)
        get "/api/v1/time_off_requests"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /api/v1/time_off_requests/:id" do
    context "as the user who owns the request" do
      it "returns the time off request" do
        login_as(employee, scope: :user)
        get "/api/v1/time_off_requests/#{employee_request.id}"
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['id'].to_i).to eq(employee_request.id)
      end
    end

    context "as the manager of the user who owns the request" do
      it "returns the time off request" do
        login_as(manager, scope: :user)
        get "/api/v1/time_off_requests/#{employee_request.id}"
        expect(response).to have_http_status(:success)
      end
    end

    context "as a user who does not own the request" do
      it "returns a forbidden status" do
        login_as(unrelated_employee, scope: :user)
        get "/api/v1/time_off_requests/#{employee_request.id}"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/time_off_requests" do
    let(:valid_params) do
      {
        time_off_request: {
          time_off_type_id: time_off_type.id,
          start_date: Date.today + 50.days,
          end_date: Date.today + 53.days,
          reason: "Vacation"
        }
      }
    end

    context "with valid parameters" do
      before do
        grant_pto(employee, 10)
        login_as(employee, scope: :user)
      end

      it "creates a new TimeOffRequest" do
        expect {
          post "/api/v1/time_off_requests", params: valid_params
        }.to change(TimeOffRequest, :count).by(1)
      end

      it "returns a :created status" do
        post "/api/v1/time_off_requests", params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          time_off_request: {
            time_off_type_id: time_off_type.id,
            start_date: Date.today - 5.days,
            end_date: Date.today - 3.days,
            reason: "Invalid request"
          }
        }
      end

      before do
        login_as(employee, scope: :user)
      end

      it "does not create a new TimeOffRequest" do
        expect {
          post "/api/v1/time_off_requests", params: invalid_params
        }.not_to change(TimeOffRequest, :count)
      end

      it "returns an :unprocessable_content status" do
        post "/api/v1/time_off_requests", params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns a descriptive error message" do
        post "/api/v1/time_off_requests", params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Start date cannot be in the past")
      end
    end
  end

  describe "PATCH /api/v1/time_off_requests/:id/approve" do
    context "as a manager" do
      before do
        login_as(manager, scope: :user)
      end

      it "approves a pending time off request" do
        patch "/api/v1/time_off_requests/#{employee_request.id}/approve"
        expect(response).to have_http_status(:success)
        employee_request.reload
        expect(employee_request.status).to eq("approved")
      end

      it "returns an error if the request is already approved" do
        employee_request.update(status: :approved)
        patch "/api/v1/time_off_requests/#{employee_request.id}/approve"
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as an admin" do
      before do
        login_as(admin, scope: :user)
      end

      it "approves any time off request" do
        patch "/api/v1/time_off_requests/#{employee_request.id}/approve"
        expect(response).to have_http_status(:success)
        employee_request.reload
        expect(employee_request.status).to eq("approved")
      end
    end

    context "as an unauthorized user" do
      it "returns forbidden status" do
        login_as(unrelated_employee, scope: :user)
        patch "/api/v1/time_off_requests/#{employee_request.id}/approve"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/time_off_requests/:id/deny" do
    context "as a manager" do
      before do
        login_as(manager, scope: :user)
      end

      it "denies a pending time off request" do
        patch "/api/v1/time_off_requests/#{employee_request.id}/deny"
        expect(response).to have_http_status(:success)
        employee_request.reload
        expect(employee_request.status).to eq("rejected")
      end

      it "returns an error if the request is already denied" do
        employee_request.update(status: :rejected)
        patch "/api/v1/time_off_requests/#{employee_request.id}/deny"
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as an admin" do
      before do
        login_as(admin, scope: :user)
      end

      it "denies any time off request" do
        patch "/api/v1/time_off_requests/#{employee_request.id}/deny"
        expect(response).to have_http_status(:success)
        employee_request.reload
        expect(employee_request.status).to eq("rejected")
      end
    end

    context "as an unauthorized user" do
      it "returns forbidden status" do
        login_as(unrelated_employee, scope: :user)
        patch "/api/v1/time_off_requests/#{employee_request.id}/deny"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v1/time_off_requests/manager_dashboard" do
    context "as a manager" do
      before do
        login_as(manager, scope: :user)
        get "/api/v1/time_off_requests/manager_dashboard"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns requests for their direct reports" do
        json_response = JSON.parse(response.body)
        request_ids = json_response['data'].map { |r| r['id'].to_i }
        expect(request_ids).to include(employee_request.id, other_employee_request.id)
      end
    end

    context "as an admin" do
      before do
        login_as(admin, scope: :user)
        get "/api/v1/time_off_requests/manager_dashboard"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "as a regular employee" do
      before do
        login_as(employee, scope: :user)
        get "/api/v1/time_off_requests/manager_dashboard"
      end

      it "returns forbidden status" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
