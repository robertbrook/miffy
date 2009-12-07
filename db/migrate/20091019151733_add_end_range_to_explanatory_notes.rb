class AddEndRangeToExplanatoryNotes < ActiveRecord::Migration
  def self.up
    add_column :explanatory_notes, :range_end, :string
  end

  def self.down
    remove_column :explanatory_notes, :range_end
  end
end
