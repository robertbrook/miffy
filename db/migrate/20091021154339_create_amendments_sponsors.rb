class CreateAmendmentsSponsors < ActiveRecord::Migration
  def self.up
    create_table :amendments_sponsors, :id => false do |t|
      t.integer :amendment_id, :null => false
      t.integer :sponsor_id, :null => false
    end
  end

  def self.down
    drop_table :amendments_sponsors
  end
end
