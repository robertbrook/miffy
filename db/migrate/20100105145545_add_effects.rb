class AddEffects < ActiveRecord::Migration
  def self.up
    create_table :effects do |t|
            t.integer :bill_id
            t.string  :affected_legislation
            t.string  :affected_provision
            t.string  :type_of_effect
            t.string  :affecting_legislation
            t.string  :affecting_provision
    end
  end

  def self.down
    drop_table :effects
  end
end

# arrrgh - add date!

# Date,
# Affected Legislation (Act),
# Affected Provision,
# Type of Effect,
# Affecting Legislation (Year and Chapter or Number),
# Affecting Provision ,
# Amendment applied to Database,
# Checked (Y or leave Blank),
# Transferred to Final TOES Chart (Date)