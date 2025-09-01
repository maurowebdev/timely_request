class CreateTimeOffLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :time_off_ledger_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :effective_date
      t.text :notes
      t.references :source, polymorphic: true, null: false

      t.timestamps
    end
    add_index :time_off_ledger_entries, :entry_type
  end
end
