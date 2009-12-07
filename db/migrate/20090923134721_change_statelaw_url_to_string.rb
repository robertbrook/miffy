class ChangeStatelawUrlToString < ActiveRecord::Migration
  def self.up
    remove_column :acts, :statutelaw_url
    remove_column :act_sections, :statutelaw_url

    add_column :acts, :statutelaw_url, :string
    add_column :act_sections, :statutelaw_url, :string
  end

  def self.down
  end
end
