class NoteByClause < ExplanatoryNote

  validates_presence_of :clause_number
  validates_length_of :range_end, :is => 0
  validates_uniqueness_of :clause_number, :scope => :bill_id

end