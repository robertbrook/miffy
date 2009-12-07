class CreateActParts < ActiveRecord::Migration
  def self.up
    create_table :act_parts do |t|
      t.integer :act_id
      t.string :name
      t.string :title
      t.string :opsi_url
      t.string :legislation_url
      t.string :statutelaw_url

      t.timestamps
    end

    add_index :act_parts, :act_id
    add_index :act_parts, :legislation_url

    add_column :act_sections, :act_part_id, :integer
    add_index :act_sections, :act_part_id
  end

  def self.down
    drop_table :act_parts
    remove_index :act_sections, :act_part_id
    remove_column :act_sections, :act_part_id
  end
end
