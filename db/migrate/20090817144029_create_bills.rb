class CreateBills < ActiveRecord::Migration
  def self.up
    create_table :bills do |t|
      t.text :name
      t.text :parliament_url

      t.timestamps
    end
    
    add_index :bills, :name
  end

  def self.down
    drop_table :bills
  end
end
