require 'rails_helper'

RSpec.describe "TimeOffRequests", type: :request do
  let(:department) { create(:department) }
  let(:user) { create(:user, department: department) }
  let(:time_off_type) { create(:time_off_type, name: "Vacation") }

  # Helper to grant PTO to a user
  def grant_pto(user, amount)
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  before do
    # Using Warden directly instead of sign_in helper
    login_as(user, scope: :user)
    grant_pto(user, 10) # Grant initial PTO to the user
  end

  describe "GET /time_off_requests/new" do
    it "returns http success" do
      get "/time_off_requests/new"
      expect(response).to have_http_status(:success)
    end

    it "includes the form for a new time off request" do
      get "/time_off_requests/new"
      expect(response.body).to include("New Time Off Request")
    end
  end

  describe "GET /time_off_requests" do
    it "returns http success" do
      get "/time_off_requests"
      expect(response).to have_http_status(:success)
    end

    it "includes a link to request time off" do
      get "/time_off_requests"
      expect(response.body).to include("Request Time Off")
    end

    it "shows the user's time off requests" do
      time_off_request = create(:time_off_request, :with_pto,
                               user: user,
                               time_off_type: time_off_type,
                               reason: "Annual vacation")

      get "/time_off_requests"
      expect(response.body).to include("Annual vacation")
    end
  end
end
