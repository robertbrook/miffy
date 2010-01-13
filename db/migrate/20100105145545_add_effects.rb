class AddEffects < ActiveRecord::Migration
  def self.up
    create_table :effects do |t|
            t.integer :bill_id
            t.string  :bill_provision
            t.string  :affected_act
            t.string  :affected_act_provision
            t.string  :type_of_effect
            t.date    :effect_date
    end
  end

  def self.down
    drop_table :effects
  end
end

# Date, -> not used as it looks wrong (would otherwise go into effect_date)
# Affected Legislation (Act), -> affected_act
# Affected Provision, -> affected_act_provision
# Type of Effect, -> type_of_effect
# Affecting Legislation (Year and Chapter or Number), -> used to compute bill_id
# Affecting Provision , -> bill_provision
# Amendment applied to Database, -> not used
# Checked (Y or leave Blank), -> not used
# Transferred to Final TOES Chart (Date) -> not used