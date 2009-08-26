class RenameTypeAsNoteType < ActiveRecord::Migration
  def self.up
    rename_column :explanatory_notes, :type, :note_type
  end

  def self.down
    rename_column :explanatory_notes, :note_type, :type
  end
end
