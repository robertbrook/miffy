class MakeSectionNumberAStringInActSections < ActiveRecord::Migration
  def self.up
    add_column :act_sections, :section_number, :string

    ActSection.find_each do |section|
      if section.number
        section.section_number = section.number.to_s
        section.save
      end
    end

    remove_column :act_sections, :number
    add_index :act_sections, :section_number
  end

  def self.down
    add_column :act_sections, :number, :integer

    ActSection.find_each do |section|
      if section.section_number
        section.number = section.section_number.to_i
        section.save
      end
    end

    remove_index :act_sections, :section_number
    remove_column :act_sections, :section_number
  end
end
