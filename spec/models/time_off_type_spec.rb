require 'rails_helper'

RSpec.describe TimeOffType, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      time_off_type = build(:time_off_type, name: nil)
      expect(time_off_type).not_to be_valid
      expect(time_off_type.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:time_off_type, name: 'Vacation')
      duplicate = build(:time_off_type, name: 'Vacation')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end

  describe 'business rules' do
    let(:vacation_type) { create(:time_off_type, name: 'Vacation') }
    let(:sick_leave_type) { create(:time_off_type, name: 'Sick Leave') }
    let(:personal_day_type) { create(:time_off_type, name: 'Personal Day') }

    describe '#requires_advance_notice?' do
      it 'returns true for Vacation' do
        expect(vacation_type.requires_advance_notice?).to be true
      end

      it 'returns false for Sick Leave' do
        expect(sick_leave_type.requires_advance_notice?).to be false
      end

      it 'returns false for Personal Day' do
        expect(personal_day_type.requires_advance_notice?).to be false
      end
    end

    describe '#advance_notice_days' do
      it 'returns 14 days for Vacation' do
        expect(vacation_type.advance_notice_days).to eq(14)
      end

      it 'returns 0 days for Sick Leave' do
        expect(sick_leave_type.advance_notice_days).to eq(0)
      end

      it 'returns 3 days for Personal Day' do
        expect(personal_day_type.advance_notice_days).to eq(3)
      end
    end

    describe '#max_consecutive_days' do
      it 'returns 30 days for Vacation' do
        expect(vacation_type.max_consecutive_days).to eq(30)
      end

      it 'returns 90 days for Sick Leave' do
        expect(sick_leave_type.max_consecutive_days).to eq(90)
      end

      it 'returns 5 days for Personal Day' do
        expect(personal_day_type.max_consecutive_days).to eq(5)
      end
    end

    describe '#requires_manager_approval?' do
      it 'returns true for Vacation' do
        expect(vacation_type.requires_manager_approval?).to be true
      end

      it 'returns false for Sick Leave' do
        expect(sick_leave_type.requires_manager_approval?).to be false
      end

      it 'returns true for Personal Day' do
        expect(personal_day_type.requires_manager_approval?).to be true
      end
    end
  end
end
