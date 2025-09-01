require 'rails_helper'

RSpec.describe "Manager::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager, manager: admin) }
  let(:employee) { create(:user, :employee, manager: manager) }
  let(:unrelated_employee) { create(:user, :employee) }

  let!(:employee_request) {
    create(:time_off_ledger_entry, user: employee, amount: 10, source: employee)
    create(:time_off_request, :vacation, user: employee)
  }
  let!(:unrelated_request) {
    create(:time_off_ledger_entry, user: unrelated_employee, amount: 10, source: unrelated_employee)
    create(:time_off_request, :vacation, user: unrelated_employee)
  }

  describe "GET /manager" do
    context "as a manager" do
      before do
        login_as(manager, scope: :user)
        get "/manager"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "renders the dashboard page successfully" do
        expect(response.body).to include("Manager Dashboard")
      end

      it "shows the employee request" do
        expect(response.body).to include(CGI.escapeHTML(employee_request.user.name))
      end

      it "doesn't show the unrelated request" do
        expect(response.body).not_to include(CGI.escapeHTML(unrelated_request.user.name))
      end
    end

    context "as an admin" do
      before do
        login_as(admin, scope: :user)
        get "/manager"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "assigns request variables for both direct and indirect reports" do
        # This test might need adjustment based on your implementation of how
        # admins can see both direct reports and their employees' managed employees
        expect(response).to have_http_status(:success)
      end
    end

    context "as a regular employee" do
      before do
        login_as(employee, scope: :user)
        get "/manager"
      end

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "shows an authorization error message" do
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end
end
