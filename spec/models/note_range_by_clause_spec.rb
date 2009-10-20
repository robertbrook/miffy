require File.dirname(__FILE__) + '/../spec_helper.rb'

describe NoteRangeByClause do
  describe 'when asked if a clause number is contained in the range' do
    
    describe 'and the range is numeric' do
      before do
        @range = NoteRangeByClause.new(:clause_number => "2", :range_end => "4", :note_text => "some text", :bill_id => 4 )
      end
      
      it 'should return true when the clause number is in the middle of the range' do
        @range.contains_clause?("3").should == true
      end
      
      it 'should return true when the clause number is at the end of the range' do
        @range.contains_clause?("4").should == true
      end
      
      it 'should return false when the clause number is beyond the end of the range' do
        @range.contains_clause?("5").should == false
      end
      
      it 'should return false when the clause number is at the start of the range' do
        @range.contains_clause?("2").should == false
      end
    end
    
    describe 'and the start of the range is a string' do
      before do
        @range = NoteRangeByClause.new(:clause_number => "2A", :range_end => "4", :note_text => "some text", :bill_id => 4 )
      end
      
      it 'should return true when the clause number is in the middle of the range' do
        @range.contains_clause?("2B").should == true
        @range.contains_clause?("3").should == true
      end
      
      it 'should return true when the clause number is at the end of the range' do
        @range.contains_clause?("4").should == true
      end
      
      it 'should return false when the clause number is outside the range' do
        @range.contains_clause?("5").should == false
        @range.contains_clause?("1").should == false
        @range.contains_clause?("2").should == false
      end
    
      it 'should return false when the clause number is at the start of the range' do
        @range.contains_clause?("2A").should == false
      end
    end
    
    describe 'and the end of the range is a string' do
      before do
        @range = NoteRangeByClause.new(:clause_number => "2", :range_end => "4D", :note_text => "some text", :bill_id => 4 )
      end
      
      it 'should return true when the clause number is in the middle of the range' do
        @range.contains_clause?("2B").should == true
        @range.contains_clause?("3").should == true
        @range.contains_clause?("4B").should == true
      end
      
      it 'should return true when the clause number is at the end of the range' do
        @range.contains_clause?("4D").should == true
      end
      
      it 'should return false when the clause number is outside the range' do
        @range.contains_clause?("5").should == false
        @range.contains_clause?("4E").should == false
        @range.contains_clause?("1").should == false
      end
    
      it 'should return false when the clause number is at the start of the range' do
        @range.contains_clause?("2").should == false
      end
    end
    
    describe 'and both ends of the range are strings' do
      before do
        @range = NoteRangeByClause.new(:clause_number => "2A", :range_end => "4D", :note_text => "some text", :bill_id => 4 )
      end
      
      it 'should return true when the clause number is in the middle of the range' do
        @range.contains_clause?("2B").should == true
        @range.contains_clause?("3").should == true
        @range.contains_clause?("4B").should == true
      end
      
      it 'should return true when the clause number is at the end of the range' do
        @range.contains_clause?("4D").should == true
      end
      
      it 'should return false when the clause number is outside the range' do
        @range.contains_clause?("5").should == false
        @range.contains_clause?("4E").should == false
        @range.contains_clause?("1").should == false
      end
    
      it 'should return false when the clause number is at the start of the range' do
        @range.contains_clause?("2A").should == false
      end
    end
  end
end