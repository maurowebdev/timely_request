# frozen_string_literal: true

RSpec.shared_context "authenticated user" do
  let(:department) { create(:department) }
  let(:user) { create(:user, department: department) }

  before do
    sign_in user
  end
end

RSpec.shared_context "authenticated manager" do
  let(:department) { create(:department) }
  let(:manager) { create(:user, :manager, department: department) }
  let(:employee) { create(:user, :employee, department: department, manager: manager) }

  before do
    sign_in manager
  end
end

RSpec.shared_context "authenticated admin" do
  let(:department) { create(:department) }
  let(:admin) { create(:user, :admin, department: department) }

  before do
    sign_in admin
  end
end
