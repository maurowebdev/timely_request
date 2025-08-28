class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :role
      t.references :department, null: false, foreign_key: true
      t.references :manager, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
