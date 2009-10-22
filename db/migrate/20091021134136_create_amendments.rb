class CreateAmendments < ActiveRecord::Migration
  def self.up
    create_table :amendments do |t|
      t.string  :type
      t.string  :title
      t.string  :amendment_number
      t.string  :reference
      t.string  :instruction
      t.text    :amendment_text
      t.integer :bill_id
      t.string  :clause_number
      t.string  :schedule_number
      t.string  :page_number
      t.string  :line_number
      t.boolean :new_clause
      t.boolean :new_schedule
    end
  end

  def self.down
    drop_table :amendments
  end
end
