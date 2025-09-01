require 'rails_helper'

RSpec.describe MonthlyPtoAccrualJob, type: :job do
  describe '#perform' do
    let!(:user1) { create(:user, :employee) }
    let!(:user2) { create(:user, :employee) }
    let!(:user3) { create(:user, :manager) }

    it 'creates a PTO accrual entry for each user' do
      expect {
        described_class.perform_now
      }.to change(TimeOffLedgerEntry, :count).by(3)
    end

    it 'creates accrual entries with correct attributes' do
      described_class.perform_now

      accrual_entries = TimeOffLedgerEntry.where(entry_type: :accrual)
      expect(accrual_entries.count).to eq(3)

      accrual_entries.each do |entry|
        expect(entry.amount).to eq(1.0)
        expect(entry.effective_date).to eq(Date.current)
        expect(entry.entry_type).to eq('accrual')
        expect(entry.notes).to include('Monthly PTO accrual')
        expect(entry.notes).to include(Date.current.strftime('%B %Y'))
        expect(entry.source).to eq(entry.user)
      end
    end

    it 'associates each accrual entry with the correct user' do
      described_class.perform_now

      expect(user1.time_off_ledger_entries.where(entry_type: :accrual).count).to eq(1)
      expect(user2.time_off_ledger_entries.where(entry_type: :accrual).count).to eq(1)
      expect(user3.time_off_ledger_entries.where(entry_type: :accrual).count).to eq(1)
    end

    it 'sets the source as the user for each entry' do
      described_class.perform_now

      accrual_entries = TimeOffLedgerEntry.where(entry_type: :accrual)
      accrual_entries.each do |entry|
        expect(entry.source).to eq(entry.user)
      end
    end

    it 'handles the case when there are no users' do
      User.delete_all

      expect {
        described_class.perform_now
      }.not_to change(TimeOffLedgerEntry, :count)
    end

    it 'creates entries with the correct accrual amount constant' do
      described_class.perform_now

      accrual_entries = TimeOffLedgerEntry.where(entry_type: :accrual)
      accrual_entries.each do |entry|
        expect(entry.amount).to eq(MonthlyPtoAccrualJob::ACCRUAL_AMOUNT)
      end
    end

    it 'includes the current month and year in the notes' do
      described_class.perform_now

      accrual_entries = TimeOffLedgerEntry.where(entry_type: :accrual)
      current_month_year = Date.current.strftime('%B %Y')

      accrual_entries.each do |entry|
        expect(entry.notes).to eq("Monthly PTO accrual for #{current_month_year}")
      end
    end

    context 'when a user already has accrual entries' do
      before do
        # Create existing accrual entry for user1
        create(:time_off_ledger_entry,
               user: user1,
               entry_type: :accrual,
               amount: 1.0,
               effective_date: 1.month.ago,
               source: user1)
      end

      it 'creates additional accrual entries without affecting existing ones' do
        expect {
          described_class.perform_now
        }.to change(TimeOffLedgerEntry, :count).by(3)

        # user1 should now have 2 accrual entries
        expect(user1.time_off_ledger_entries.where(entry_type: :accrual).count).to eq(2)
      end
    end

    context 'error handling' do
      it 'raises an error if ledger entry creation fails' do
        allow(TimeOffLedgerEntry).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(TimeOffLedgerEntry.new))

        expect {
          described_class.perform_now
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
