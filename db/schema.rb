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

ActiveRecord::Schema[8.1].define(version: 2026_04_12_123942) do
  create_table "bookings", force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "checked_in_at"
    t.string "contact_email"
    t.string "contact_person"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time", null: false
    t.integer "estimated_attendance"
    t.boolean "is_recurring", default: false
    t.integer "lock_version", default: 0, null: false
    t.integer "parent_booking_id"
    t.datetime "recurrence_end_date"
    t.string "recurrence_pattern"
    t.text "special_requirements"
    t.datetime "start_time", null: false
    t.integer "status", default: 0
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "venue_id", null: false
    t.index ["start_time", "end_time"], name: "index_bookings_on_start_time_and_end_time"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.index ["venue_id"], name: "index_bookings_on_venue_id"
  end

  create_table "cancellations", force: :cascade do |t|
    t.integer "booking_id", null: false
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.float "hours_before_start"
    t.boolean "is_late_cancellation", default: false
    t.integer "points_deducted", default: 0
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_cancellations_on_booking_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "equipment_type"
    t.string "image_url"
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.integer "quantity", default: 1
    t.string "status", default: "available"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_equipment_on_tenant_id"
  end

  create_table "equipment_bookings", force: :cascade do |t|
    t.integer "booking_id", null: false
    t.datetime "created_at", null: false
    t.integer "equipment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_equipment_bookings_on_booking_id"
    t.index ["equipment_id"], name: "index_equipment_bookings_on_equipment_id"
  end

  create_table "point_deductions", force: :cascade do |t|
    t.integer "booking_id"
    t.datetime "created_at", null: false
    t.integer "points"
    t.string "reason"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["booking_id"], name: "index_point_deductions_on_booking_id"
    t.index ["user_id"], name: "index_point_deductions_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.integer "cancellation_deadline_hours", default: 24
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.integer "max_recurring_days", default: 180
    t.string "name", null: false
    t.integer "point_deduction_per_late_cancel", default: 10
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tenants_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name"
    t.string "hashed_password", null: false
    t.boolean "is_active", default: true
    t.integer "points", default: 100
    t.integer "role", default: 0
    t.datetime "suspension_until"
    t.integer "tenant_id"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "available_from", default: "08:00"
    t.string "available_until", default: "22:00"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.json "features", default: {}
    t.string "image_url"
    t.boolean "is_active", default: true
    t.float "latitude"
    t.string "location"
    t.float "longitude"
    t.string "name", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_venues_on_tenant_id"
  end

  add_foreign_key "bookings", "users"
  add_foreign_key "bookings", "venues"
  add_foreign_key "cancellations", "bookings"
  add_foreign_key "equipment", "tenants"
  add_foreign_key "equipment_bookings", "bookings"
  add_foreign_key "equipment_bookings", "equipment"
  add_foreign_key "point_deductions", "bookings"
  add_foreign_key "point_deductions", "users"
  add_foreign_key "users", "tenants"
  add_foreign_key "venues", "tenants"
end
