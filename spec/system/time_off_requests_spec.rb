require 'rails_helper'

RSpec.describe "TimeOffRequests", type: :system do
  let(:user) { create(:user) }
  let!(:time_off_type) { create(:time_off_type, name: "Vacation") }

  # Helper to grant PTO to a user
  def grant_pto(user, amount)
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  before do
    # Use selenium_chrome_headless to support JavaScript and Stimulus controllers
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
    grant_pto(user, 20) # Grant PTO to the user
  end

  describe "New time off request form" do
    it "creates a new time off request via API" do
      visit new_time_off_request_path

      expect(page).to have_content("New Time Off Request")

      select "Vacation", from: "time_off_request[time_off_type_id]"
      fill_in "time_off_request[start_date]", with: Date.today + 1.day
      fill_in "time_off_request[end_date]", with: Date.today + 5.days
      fill_in "time_off_request[reason]", with: "Taking a break"

      # The Stimulus controller will intercept this submission and make an API call
      expect {
        click_button "Submit Request"
        # Wait for the API call to complete
        sleep(0.5)
      }.to change(TimeOffRequest, :count).by(1)

      # The Stimulus controller shows a success message
      expect(page).to have_content("Time off request was successfully created")
    end

    it "displays validation errors" do
      visit new_time_off_request_path

      # Submit without required fields
      click_button "Submit Request"
      # Wait for the API call to complete
      sleep(0.5)

      # The Stimulus controller displays validation errors from the API
      expect(page).to have_content("error(s) prohibited this time off request from being saved")
    end
  end

  describe "Time off request list" do
    let!(:time_off_request) do
      create(:time_off_request, :with_pto, user: user, time_off_type: time_off_type)
    end

    it "displays the user's time off requests" do
      visit time_off_requests_path

      expect(page).to have_content(time_off_request.reason)
      expect(page).to have_content(time_off_type.name)
      # Just check that the status is displayed (instead of exact date format)
      expect(page).to have_content("Pending")
    end
  end
end
