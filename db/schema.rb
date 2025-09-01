# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_31_213011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "approvals", force: :cascade do |t|
    t.bigint "time_off_request_id", null: false
    t.bigint "approver_id", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_approvals_on_approver_id"
    t.index ["time_off_request_id"], name: "index_approvals_on_time_off_request_id", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_off_ledger_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "entry_type", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "effective_date"
    t.text "notes"
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_type"], name: "index_time_off_ledger_entries_on_entry_type"
    t.index ["source_type", "source_id"], name: "index_time_off_ledger_entries_on_source"
    t.index ["user_id"], name: "index_time_off_ledger_entries_on_user_id"
  end

  create_table "time_off_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "time_off_type_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "reason"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["time_off_type_id"], name: "index_time_off_requests_on_time_off_type_id"
    t.index ["user_id"], name: "index_time_off_requests_on_user_id"
  end

  create_table "time_off_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.integer "role"
    t.bigint "department_id", null: false
    t.bigint "manager_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "approvals", "time_off_requests"
  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "time_off_ledger_entries", "users"
  add_foreign_key "time_off_requests", "time_off_types"
  add_foreign_key "time_off_requests", "users"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "users", column: "manager_id"
end
