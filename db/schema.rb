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

ActiveRecord::Schema[8.0].define(version: 2025_03_17_214559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.string "postal_code"
    t.string "street"
    t.string "building"
    t.string "apartment"
    t.string "postal_city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "nip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_types", force: :cascade do |t|
    t.string "invoice_type"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.string "name"
    t.bigint "company_id"
    t.bigint "invoice_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "invoice_date"
    t.integer "brutto"
    t.integer "vat"
    t.integer "netto"
    t.string "invoice_nr"
    t.boolean "image_pdf_created", default: false
    t.string "file_path"
    t.string "invoice_status", default: "initial"
    t.string "description_error"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["invoice_type_id"], name: "index_invoices_on_invoice_types_id"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "addresses_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addresses_id"], name: "index_locations_on_addresses_id"
    t.index ["company_id"], name: "index_locations_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "locations", "addresses", column: "addresses_id"
  add_foreign_key "locations", "companies"
end
