require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }

  describe "GET /index" do
    context "when a user is signed in" do
      before do
        sign_in(user, scope: :user)
        get root_path
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when a user is not signed in" do
      it "redirects to the sign-in page" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
