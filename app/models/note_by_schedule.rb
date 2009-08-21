class NoteBySchedule < ExplanatoryNote

  validates_presence_of :schedule_number
  validates_uniqueness_of :schedule_number, :scope => :bill_id

end
