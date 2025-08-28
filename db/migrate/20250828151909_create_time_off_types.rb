class CreateTimeOffTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :time_off_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
