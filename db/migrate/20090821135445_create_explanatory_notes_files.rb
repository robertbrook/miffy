class CreateExplanatoryNotesFiles < ActiveRecord::Migration
  def self.up
    create_table :explanatory_notes_files do |t|
      t.string :name
      t.integer :bill_id
      t.string :path
      t.text :beginning_text
      t.text :ending_text

      t.timestamps
    end

    add_index :explanatory_notes_files, :bill_id
    add_index :explanatory_notes_files, :path
  end

  def self.down
    drop_table :explanatory_notes_files
  end
end
