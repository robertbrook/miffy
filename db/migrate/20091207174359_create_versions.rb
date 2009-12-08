class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.date    :printed_date
      t.string  :bill_number
      t.string  :session_number
      t.string  :house
      t.integer :bill_id
    end
  end

  def self.down
    drop_table :versions
  end
end
