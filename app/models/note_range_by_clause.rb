class NoteRangeByClause < ExplanatoryNote
  
  validates_presence_of :clause_number
  validates_presence_of :range_end
  validates_uniqueness_of :clause_number, :scope => :bill_id
  
  
  def contains_clause? clause
    clause = clause.to_s
    numeric_clause = clause.to_i
    numeric_start = clause_number.to_i
    numeric_end = range_end.to_i
    
    start_in_range = false
    
    #check if the clause is in the middle of the range
    if numeric_clause > numeric_start && numeric_clause < numeric_end
      return true
    end
    
    #check if the clause is at the end of the range
    if clause == range_end
      return true
    end
    
    #check that the start of the range is *not* numeric
    unless numeric_start.to_s == clause_number || clause == clause_number
      range = [clause_number, clause]
      range.sort!
      if range[1] == clause
        start_in_range = true
      end
    end
    
    #check that the start of the range is numeric
    if numeric_start.to_s == clause_number
      #the clause is numeric and greater than the start of the range
      if numeric_clause.to_s == clause && numeric_clause > numeric_start
        start_in_range = true
      elsif numeric_clause.to_s != clause && numeric_clause >= numeric_start
        start_in_range = true
      end
    end
    
    if start_in_range
      #check whether the clause is below the end of the range
      if numeric_clause < numeric_end
        return true
      end
      #check that the end of the range is *not* numeric
      unless numeric_end.to_s == range_end
        range = [range_end, clause]
        range.sort!
        if range[0] == clause
          return true
        end
      end
    end
    false
  end
  
end