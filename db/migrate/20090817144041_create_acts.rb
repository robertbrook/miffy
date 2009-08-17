class CreateActs < ActiveRecord::Migration
  def self.up
    create_table :acts do |t|
      t.text :name
      t.text :title
      t.integer :year
      t.integer :number
      t.text :opsi_url
      t.text :statutelaw_url
      t.text :legislation_url

      t.timestamps
    end

    add_index :acts, :name
  end

  def self.down
    drop_table :acts
  end
end
