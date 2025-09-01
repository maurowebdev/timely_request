require 'rails_helper'

RSpec.describe User, type: :model do
  # Use subject to define the default user for tests, ensuring a department is always present.
  subject(:user) { build(:user, department: department) }
  let(:department) { create(:department) }

  describe 'associations' do
    it 'belongs to a department' do
      assoc = described_class.reflect_on_association(:department)
      expect(assoc.macro).to eq :belongs_to
    end

    it 'can have a manager' do
      assoc = described_class.reflect_on_association(:manager)
      expect(assoc.macro).to eq :belongs_to
      expect(assoc.options[:class_name]).to eq 'User'
    end

    it 'can have many managed employees' do
      assoc = described_class.reflect_on_association(:managed_employees)
      expect(assoc.macro).to eq :has_many
      expect(assoc.options[:class_name]).to eq 'User'
      expect(assoc.options[:foreign_key]).to eq 'manager_id'
    end

    it 'has many time_off_requests' do
      assoc = described_class.reflect_on_association(:time_off_requests)
      expect(assoc.macro).to eq :has_many
    end

    it 'has many time_off_ledger_entries' do
      assoc = described_class.reflect_on_association(:time_off_ledger_entries)
      expect(assoc.macro).to eq :has_many
    end
  end

  describe 'enums' do
    it 'defines the role enum correctly' do
      expect(described_class.roles).to eq({ "employee" => 0, "manager" => 1, "admin" => 2 })
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'is invalid without a department' do
      user.department = nil
      expect(user).not_to be_valid
      expect(user.errors[:department]).to include("must exist")
    end

    # Devise handles email and password validations, but we can test for completeness.
    it 'is invalid without an email' do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      create(:user, email: 'test@example.com', department: department)
      user.email = 'test@example.com'
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end
  end

  describe 'custom validations: manager hierarchy' do
    it 'is invalid if a user is their own manager' do
      user.manager = user
      expect(user).not_to be_valid
      expect(user.errors[:manager]).to include("can't be yourself")
    end

    it 'is invalid if it creates a direct circular reference' do
      manager = create(:user, department: department)
      employee = create(:user, manager: manager, department: department)

      # Now, try to make the manager report to the employee
      manager.manager = employee
      expect(manager).not_to be_valid
      expect(manager.errors[:manager_id]).to include("creates a circular reference")
    end

    it 'is invalid if it creates a multi-level circular reference' do
      level1_manager = create(:user, department: department)
      level2_manager = create(:user, manager: level1_manager, department: department)
      employee = create(:user, manager: level2_manager, department: department)

      # Complete the loop
      level1_manager.manager = employee
      expect(level1_manager).not_to be_valid
      expect(level1_manager.errors[:manager_id]).to include("creates a circular reference")
    end

    it 'is valid with a valid manager' do
      manager = create(:user, department: department)
      user.manager = manager
      expect(user).to be_valid
    end
  end

  describe '#pto_balance' do
    it 'correctly calculates the sum of ledger entries' do
      user = create(:user, department: department)
      create(:time_off_ledger_entry, user: user, amount: 10, source: user)
      create(:time_off_ledger_entry, user: user, amount: 5, source: user)
      create(:time_off_ledger_entry, user: user, amount: -3, source: user)
      expect(user.pto_balance).to eq(12)
    end

    it 'returns 0 if there are no ledger entries' do
       user = create(:user, department: department)
       expect(user.pto_balance).to eq(0)
    end
  end
end
