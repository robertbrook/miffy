class RepopulateOpsiUrlForActs < ActiveRecord::Migration
  def self.up
    Act.find_each {|x| x.populate_opsi_url(true); x.save }
  end

  def self.down
  end
end
