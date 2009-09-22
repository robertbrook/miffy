class CreateActSections < ActiveRecord::Migration
  def self.up
    create_table :act_sections do |t|
      t.integer :act_id
      t.integer :number
      t.string :title
      t.string :opsi_url
      t.string :legislation_url
      t.text :statutelaw_url

      t.timestamps
    end

    remove_column :acts, :opsi_url
    remove_column :acts, :legislation_url

    add_column :acts, :opsi_url, :string
    add_column :acts, :legislation_url, :string

    add_index :act_sections, :act_id
    add_index :act_sections, :legislation_url
    add_index :acts, :legislation_url

    Act.find_each {|x| x.save }
  end

  def self.down
    drop_table :act_sections
  end
end
