class AddFileTypeToMifFiles < ActiveRecord::Migration
  def self.up
    add_column :mif_files, :file_type, :string
  end

  def self.down
    remove_column :mif_files, :file_type
  end
end
