require 'rails_helper'

RSpec.describe User, type: :model do
  let(:department) { create(:department) }

  describe 'associations' do
    it 'belongs to a department' do
      user = build(:user, department: department)
      expect(user).to respond_to(:department)
    end

    it 'can have a manager' do
      manager = create(:user, :manager, department: department)
      employee = create(:user, :employee, manager: manager, department: department)
      expect(employee.manager).to eq(manager)
    end

    it 'can have many managed employees' do
      manager = create(:user, :manager, department: department)
      employee1 = create(:user, :employee, manager: manager, department: department)
      employee2 = create(:user, :employee, manager: manager, department: department)
      expect(manager.managed_employees).to include(employee1, employee2)
    end

    it 'has many time off requests' do
      user = create(:user, department: department)
      # Note: time_off_request factory might need a user, so we pass it in.
      # Assuming the factory is set up for this.
      time_off_type = create(:time_off_type)
      create_list(:time_off_request, 2, user: user, time_off_type: time_off_type)
      expect(user.time_off_requests.count).to eq(2)
    end
  end

  describe 'enums' do
    it 'defines the role enum correctly' do
      expect(User.roles).to eq({ "employee" => 0, "manager" => 1, "admin" => 2 })
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:user, department: department)).to be_valid
    end

    it 'is invalid without an email' do
      user = build(:user, email: nil, department: department)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      existing_user = create(:user, department: department)
      user = build(:user, email: existing_user.email, department: department)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end
  end

  describe 'manager hierarchy validations' do
    context 'when a user is their own manager' do
      it 'is not valid' do
        user = build(:user, department: department)
        user.manager = user
        expect(user).not_to be_valid
        expect(user.errors[:manager]).to include("can't be yourself")
      end
    end

    context 'when creating a circular reference' do
      it 'is not valid' do
        manager = create(:user, :manager, department: department)
        employee = create(:user, :employee, manager: manager, department: department)

        # Attempt to create the loop: manager -> employee -> manager
        manager.manager = employee
        expect(manager).not_to be_valid
        expect(manager.errors[:manager_id]).to include("creates a circular reference")
      end

      it 'is not valid with a longer loop' do
        admin = create(:user, :admin, department: department)
        manager = create(:user, :manager, manager: admin, department: department)
        employee = create(:user, :employee, manager: manager, department: department)

        # Attempt to create the loop: admin -> manager -> employee -> admin
        admin.manager = employee
        expect(admin).not_to be_valid
        expect(admin.errors[:manager_id]).to include("creates a circular reference")
      end
    end

    context 'with a valid manager assignment' do
      it 'is valid' do
        manager = create(:user, :manager, department: department)
        employee = build(:user, manager: manager, department: department)
        expect(employee).to be_valid
      end

      it 'is valid when changing to another valid manager' do
        manager1 = create(:user, :manager, department: department)
        manager2 = create(:user, :manager, department: department)
        employee = create(:user, manager: manager1, department: department)

        employee.manager = manager2
        expect(employee).to be_valid
      end

      it 'is valid when assigned no manager' do
        manager = create(:user, :manager, department: department)
        employee = create(:user, manager: manager, department: department)

        employee.manager = nil
        expect(employee).to be_valid
      end
    end
  end
end
