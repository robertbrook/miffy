class NoteByClause < ExplanatoryNote

  validates_presence_of :clause_number
  validates_uniqueness_of :clause_number, :scope => :bill_id

end
