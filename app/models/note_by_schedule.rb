class NoteBySchedule < ExplanatoryNote

  validates_presence_of :schedule_number
  validates_length_of :range_end, :is => 0
  validates_uniqueness_of :schedule_number, :scope => :bill_id

end
