class AddSerialNumberToExplanatoryNote < ActiveRecord::Migration
  def self.up
    add_column :explanatory_notes, :serial_number, :integer
  end

  def self.down
    remove_column :explanatory_notes, :serial_number
  end
end
