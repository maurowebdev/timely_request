require 'rails_helper'

RSpec.describe TimeOffRequest, type: :model do
  let(:employee) { create(:user, :employee) }
  let(:vacation_type) { create(:time_off_type, name: 'Vacation') }
  let(:sick_type) { create(:time_off_type, name: 'Sick Leave') }

  # Helper to create a valid ledger entry for tests
  def grant_pto(user, amount)
    # Using the user as the source for simplicity in these tests
    create(:time_off_ledger_entry, user: user, amount: amount, source: user)
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        grant_pto(employee, 20)
        request = build(:time_off_request, user: employee, time_off_type: vacation_type)
        expect(request).to be_valid
      end
    end

    context 'presence' do
      it 'is invalid without a start_date' do
        request = build(:time_off_request, start_date: nil)
        request.valid?
        expect(request.errors[:start_date]).to include("can't be blank")
      end

      it 'is invalid without an end_date' do
        request = build(:time_off_request, end_date: nil)
        request.valid?
        expect(request.errors[:end_date]).to include("can't be blank")
      end

      it 'is invalid without a reason' do
        request = build(:time_off_request, reason: nil)
        request.valid?
        expect(request.errors[:reason]).to include("can't be blank")
      end
    end

    context 'date logic' do
      it 'is invalid if the end date is before the start date' do
        request = build(:time_off_request, user: employee, start_date: Date.today, end_date: Date.yesterday)
        expect(request).not_to be_valid
        expect(request.errors[:end_date]).to include('must be after start date')
      end

      it 'is invalid if the start date is in the past' do
        request = build(:time_off_request, user: employee, start_date: Date.yesterday)
        expect(request).not_to be_valid
        expect(request.errors[:start_date]).to include('cannot be in the past')
      end

      it 'is valid if the start date is today' do
        grant_pto(employee, 20)
        request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today, end_date: Date.today + 1.day)
        expect(request).to be_valid
      end
    end

    context 'overlapping requests' do
      before do
        grant_pto(employee, 30) # Grant enough PTO for all tests here
        create(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 10.days, end_date: Date.today + 15.days)
      end

      it 'is invalid if it starts within an existing request' do
        overlapping_request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 12.days, end_date: Date.today + 17.days)
        expect(overlapping_request).not_to be_valid
        expect(overlapping_request.errors[:base]).to include(/overlapping requests found/)
      end

      it 'is invalid if it ends within an existing request' do
        overlapping_request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 8.days, end_date: Date.today + 12.days)
        expect(overlapping_request).not_to be_valid
        expect(overlapping_request.errors[:base]).to include(/overlapping requests found/)
      end

      it 'is invalid if it spans over an existing request' do
        overlapping_request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 8.days, end_date: Date.today + 17.days)
        expect(overlapping_request).not_to be_valid
        expect(overlapping_request.errors[:base]).to include(/overlapping requests found/)
      end

      it 'is valid if it does not overlap' do
        non_overlapping_request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 20.days, end_date: Date.today + 25.days)
        expect(non_overlapping_request).to be_valid
      end

      it 'is valid if it overlaps with a request for a different user' do
        other_employee = create(:user, :employee)
        grant_pto(other_employee, 20)
        request = build(:time_off_request, user: other_employee, time_off_type: vacation_type, start_date: Date.today + 12.days, end_date: Date.today + 17.days)
        expect(request).to be_valid
      end
    end

    context 'PTO balance' do
      it 'is invalid if the user has insufficient PTO for a vacation request' do
        grant_pto(employee, 5)
        request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 1.day, end_date: Date.today + 6.days)
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include(/You do not have enough PTO/)
      end

      it 'is valid if the user has exactly enough PTO for a vacation request' do
        grant_pto(employee, 6)
        request = build(:time_off_request, user: employee, time_off_type: vacation_type, start_date: Date.today + 1.day, end_date: Date.today + 6.days)
        expect(request).to be_valid
      end

      it 'is valid for non-vacation requests, regardless of balance' do
        grant_pto(employee, 0)
        request = build(:time_off_request, user: employee, time_off_type: sick_type, start_date: Date.today + 1.day, end_date: Date.today + 6.days)
        expect(request).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      assoc = described_class.reflect_on_association(:user)
      expect(assoc.macro).to eq :belongs_to
    end

    it 'belongs to a time_off_type' do
      assoc = described_class.reflect_on_association(:time_off_type)
      expect(assoc.macro).to eq :belongs_to
    end

    it 'has one approval' do
      assoc = described_class.reflect_on_association(:approval)
      expect(assoc.macro).to eq :has_one
      expect(assoc.options[:dependent]).to eq :destroy
    end
  end

  describe '#duration_in_days' do
    it 'calculates the correct duration for a multi-day request' do
      request = build(:time_off_request, start_date: Date.today, end_date: Date.today + 4.days)
      expect(request.duration_in_days).to eq(5)
    end

    it 'calculates the correct duration for a single-day request' do
      request = build(:time_off_request, start_date: Date.today, end_date: Date.today)
      expect(request.duration_in_days).to eq(1)
    end
  end
end
