class AddPrintedDateSessionNumberBillNumberToMifFiles < ActiveRecord::Migration
  def self.up
    add_column :mif_files, :bill_number, :string
    add_column :mif_files, :session_number, :string
    add_column :mif_files, :printed_date, :date
  end

  def self.down
    remove_column :mif_files, :bill_number
    remove_column :mif_files, :session_number
    remove_column :mif_files, :printed_date
  end
end
