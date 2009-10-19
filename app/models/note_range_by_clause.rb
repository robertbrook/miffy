class NoteRangeByClause < ExplanatoryNote
  
  validates_presence_of :clause_number
  validates_presence_of :range_end
  validates_uniqueness_of :clause_number, :scope => :bill_id
  
end