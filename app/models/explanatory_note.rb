class ExplanatoryNote < ActiveRecord::Base

  belongs_to :explanatory_notes_file
  belongs_to :bill

  validates_presence_of :note_text

  def html_note_text
    note_text.gsub("\n", "<br />").gsub("  ", "")
  end

end
