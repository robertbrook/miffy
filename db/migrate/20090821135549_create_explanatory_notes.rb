class CreateExplanatoryNotes < ActiveRecord::Migration
  def self.up
    create_table :explanatory_notes do |t|
      t.string :type
      t.integer :bill_id
      t.integer :explanatory_notes_file_id
      t.string :clause_number
      t.string :schedule_number
      t.text :note_text

      t.timestamps
    end

    add_index :explanatory_notes, :bill_id
    add_index :explanatory_notes, :explanatory_notes_file_id

    add_index :explanatory_notes,  [:bill_id, :clause_number],   :unique => true, :name => 'by_bill_clause'
    add_index :explanatory_notes,  [:bill_id, :schedule_number], :unique => true, :name => 'by_bill_schedule'
  end

  def self.down
    drop_table :explanatory_notes
  end
end
