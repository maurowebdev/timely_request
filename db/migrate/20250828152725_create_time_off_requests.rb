class CreateTimeOffRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :time_off_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :time_off_type, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.text :reason
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
