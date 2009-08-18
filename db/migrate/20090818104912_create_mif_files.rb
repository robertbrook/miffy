class CreateMifFiles < ActiveRecord::Migration
  def self.up
    create_table :mif_files do |t|
      t.string :name
      t.integer :bill_id
      t.string :path

      t.timestamps
    end
    
    add_index :mif_files, :bill_id
    add_index :mif_files, :path
  end

  def self.down
    drop_table :mif_files
  end
end
