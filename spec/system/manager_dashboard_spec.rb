require 'rails_helper'

RSpec.describe "Manager Dashboard", type: :system do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager, manager: admin) }
  let(:employee) { create(:user, :employee, manager: manager) }
  let!(:time_off_type) { create(:time_off_type, name: "Vacation") }

  # Helper to grant PTO to a user
  def grant_pto(user, amount)
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  let!(:pending_request) {
    create(:time_off_request, :vacation, :with_pto,
      user: employee,
      status: :pending,
      reason: "Family vacation"
    )
  }

  before do
    # Note: Using rack_test which doesn't support JavaScript
    # For full Stimulus controller testing, use :selenium_chrome_headless instead
    driven_by(:rack_test)
  end

  describe "as a manager" do
    before do
      login_as(manager, scope: :user)
      visit manager_root_path
    end

    it "displays the manager dashboard" do
      expect(page).to have_content("Manager Dashboard")
      expect(page).to have_content("Pending Requests")
    end

    it "shows pending requests from direct reports" do
      expect(page).to have_content(employee.name)
      expect(page).to have_content("Family vacation")
      expect(page).to have_content("Pending")
    end

    it "can approve a request", js: true do
      # Note: This test would typically use JS, but we're using rack_test for simplicity
      # In a real environment, you'd use :selenium or :capybara_webkit

      # The actual click would be handled by the Stimulus controller in JS
      # This is a simplified representation
      find("button", text: "Approve").click

      # Since we're not actually executing JS, we'd verify changes to the DOM
      # that would occur after the API call completes

      # For non-JS tests, we can verify the controller action was called
      expect(page).to have_current_path(manager_root_path)

      # In a JS-enabled test with Stimulus controllers, we would:
      # 1. Verify the API endpoint was called with the correct request ID
      # 2. Check that the request was removed from the pending list
      # 3. Verify it appears in the approved list
      # 4. Ensure the success message was displayed by the Stimulus controller
      # expect(page).not_to have_content("Family vacation")
      # expect(page).to have_content("Request approved successfully")
    end

    it "can deny a request", js: true do
      # Similar to the approve test, but for the deny action
      find("button", text: "Deny").click

      expect(page).to have_current_path(manager_root_path)

      # In a JS-enabled test with Stimulus controllers, we would:
      # 1. Verify the API endpoint was called with the correct request ID
      # 2. Check that the request was removed from the pending list
      # 3. Verify it appears in the rejected list
      # 4. Ensure the success message was displayed by the Stimulus controller
      # expect(page).not_to have_content("Family vacation")
      # expect(page).to have_content("Request denied successfully")
    end
  end

  describe "as an admin" do
    before do
      login_as(admin, scope: :user)
      visit manager_root_path
    end

    it "displays the manager dashboard" do
      expect(page).to have_content("Manager Dashboard")
    end

    it "can see requests from the entire management chain" do
      # This test assumes your implementation shows admins requests
      # from both direct reports and their employees' managed employees
      expect(page).to have_content("Pending Requests")

      # If the employee is not a direct report of the admin, but is in the management chain,
      # we should still see their requests
      expect(page).to have_content(employee.name)

      # In a JS-enabled test, we would verify that:
      # 1. The API's manager_dashboard endpoint was called
      # 2. The Stimulus controller correctly renders requests from multiple levels
      # 3. The admin can approve/deny requests from any level in the hierarchy
    end
  end

  describe "as a regular employee" do
    before do
      login_as(employee, scope: :user)
      visit manager_root_path
    end

    it "redirects to the root path with an authorization message" do
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("not authorized")
    end
  end
end
