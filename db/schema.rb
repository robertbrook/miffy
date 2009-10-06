# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090923135802) do

  create_table "act_parts", :force => true do |t|
    t.integer  "act_id"
    t.string   "name"
    t.string   "title"
    t.string   "opsi_url"
    t.string   "legislation_url"
    t.string   "statutelaw_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "act_parts", ["act_id"], :name => "index_act_parts_on_act_id"
  add_index "act_parts", ["legislation_url"], :name => "index_act_parts_on_legislation_url"

  create_table "act_sections", :force => true do |t|
    t.integer  "act_id"
    t.integer  "number"
    t.string   "title"
    t.string   "opsi_url"
    t.string   "legislation_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "statutelaw_url"
    t.integer  "act_part_id"
  end

  add_index "act_sections", ["act_id"], :name => "index_act_sections_on_act_id"
  add_index "act_sections", ["act_part_id"], :name => "index_act_sections_on_act_part_id"
  add_index "act_sections", ["legislation_url"], :name => "index_act_sections_on_legislation_url"

  create_table "acts", :force => true do |t|
    t.string   "name"
    t.text     "title"
    t.integer  "year"
    t.integer  "number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "opsi_url"
    t.string   "legislation_url"
    t.string   "statutelaw_url"
  end

  add_index "acts", ["legislation_url"], :name => "index_acts_on_legislation_url"
  add_index "acts", ["name"], :name => "index_acts_on_name"

  create_table "bills", :force => true do |t|
    t.string   "name"
    t.text     "parliament_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bills", ["name"], :name => "index_bills_on_name"

  create_table "explanatory_notes", :force => true do |t|
    t.string   "type"
    t.integer  "bill_id"
    t.integer  "explanatory_notes_file_id"
    t.string   "clause_number"
    t.string   "schedule_number"
    t.text     "note_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "explanatory_notes", ["bill_id", "clause_number"], :name => "by_bill_clause", :unique => true
  add_index "explanatory_notes", ["bill_id", "schedule_number"], :name => "by_bill_schedule", :unique => true
  add_index "explanatory_notes", ["bill_id"], :name => "index_explanatory_notes_on_bill_id"
  add_index "explanatory_notes", ["explanatory_notes_file_id"], :name => "index_explanatory_notes_on_explanatory_notes_file_id"

  create_table "explanatory_notes_files", :force => true do |t|
    t.string   "name"
    t.integer  "bill_id"
    t.string   "path"
    t.text     "beginning_text"
    t.text     "ending_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "explanatory_notes_files", ["bill_id"], :name => "index_explanatory_notes_files_on_bill_id"
  add_index "explanatory_notes_files", ["path"], :name => "index_explanatory_notes_files_on_path"

  create_table "mif_files", :force => true do |t|
    t.string   "name"
    t.integer  "bill_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "html_page_title"
    t.string   "file_type"
  end

  add_index "mif_files", ["bill_id"], :name => "index_mif_files_on_bill_id"
  add_index "mif_files", ["path"], :name => "index_mif_files_on_path"

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.integer  "sluggable_id"
    t.integer  "sequence",                     :default => 1, :null => false
    t.string   "sluggable_type", :limit => 40
    t.string   "scope",          :limit => 40
    t.datetime "created_at"
  end

  add_index "slugs", ["name", "sluggable_type", "scope", "sequence"], :name => "index_slugs_on_name_and_sluggable_type_and_scope_and_sequence", :unique => true
  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"

end
