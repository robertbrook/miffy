class PopulateActAttributes < ActiveRecord::Migration
  def self.up
    Act.find_each {|x| x.valid?; x.save }
  end

  def self.down
  end
end
