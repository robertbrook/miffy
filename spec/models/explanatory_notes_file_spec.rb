require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ExplanatoryNotesFile do

  before do
    @file_path = '/path/to/notes.pdf'
  end

  describe 'when creating file' do
    def create
      @file = ExplanatoryNotesFile.new :path=>@file_path
      @file.stub!(:load_notes)
      @file.stub!(:set_bill)
      @file.save
    end

    it 'should set name from file_path' do
      create
      @file.name.should == 'notes'
    end

    it 'should parse pdf file' do
      create
      @file = ExplanatoryNotesFile.new :path=>@file_path, :bill_id=>5
      @file.should_receive(:load_notes)
      @file.stub!(:set_bill)
      @file.save
    end

    it 'should set bill' do
      @file = ExplanatoryNotesFile.new :path=>@file_path
      @file.stub!(:load_notes)
      @file.should_receive(:set_bill)
      @file.save
    end

    after do
      @file.delete
    end
  end

  describe 'when loading files' do
    it 'should create a ExplanatoryNotesFile for each file' do
      ExplanatoryNotesFile.should_receive(:find_or_create_by_path).with(@file_path).and_return mock('ExplanatoryNotesFile')
      ExplanatoryNotesFile.load [@file_path]
    end
  end

  describe 'with a notes file' do
    before do
      @file = ExplanatoryNotesFile.new :path => @file_path
      @number1 = '470'
      @number2 = '471'
      @text1 = 'Clause 470'
      @text2 = 'Clause 471'
      @text3 = 'Schedule 470'
      @text4 = 'Schedule 471'
      @serial1 = '480'
      @serial2 = '481'
      @bill_id = 4
      @file_id = 2
      @clauses = [[@number1,@text1,@serial1],[@number2,@text2,@serial2]]
      @schedules = [[@number1, @text3,@serial1], [@number2, @text4,@serial2]]
      @file.stub!(:id).and_return @file_id
      @file.stub!(:bill_id).and_return @bill_id
    end

    describe 'when getting clauses' do
      it 'should return array of clauses' do
        xml = '<Document><Clause Number="470" SerialNumber="480">Clause 470</Clause>
        <Clause Number="471" SerialNumber="481">Clause 471</Clause></Document>'
        @file.get_clauses(xml).should == @clauses
      end
    end
    
    describe 'when getting schedules' do
      it 'should return array of schedules' do
        xml = '<Document><Schedule Number="470" SerialNumber="480">Schedule 470</Schedule>
        <Schedule Number="471" SerialNumber="481">Schedule 471</Schedule></Document>'
        @file.get_schedules(xml).should == @schedules
      end
    end

    describe 'when setting bill' do
      it 'should find or create bill' do

      end
    end

    describe 'when loading notes' do
      it 'should parse file' do
        xml = '<xml>'
        ExplanatoryNotesParser.should_receive(:parse).with(@file_path).and_return xml
        @file.should_receive(:get_clauses).with(xml).and_return @clauses
        @file.should_receive(:get_schedules).with(xml).and_return @schedules
        note1 = mock('note1')
        note2 = mock('note2')
        note3 = mock('note3')
        note4 = mock('note4')
        note1.should_receive(:save!)
        note2.should_receive(:save!)
        note3.should_receive(:save!)
        note4.should_receive(:save!)
        NoteByClause.should_receive(:new).with(:note_text => @text1, :explanatory_notes_file_id => @file_id, :bill_id => @bill_id, :clause_number => @number1, :serial_number => @serial1.to_i).and_return note1
        NoteByClause.should_receive(:new).with(:note_text => @text2, :explanatory_notes_file_id => @file_id, :bill_id => @bill_id, :clause_number => @number2, :serial_number => @serial2.to_i).and_return note2
        NoteBySchedule.should_receive(:new).with(:note_text => @text3, :explanatory_notes_file_id => @file_id, :bill_id => @bill_id, :schedule_number => @number1, :serial_number => @serial1.to_i).and_return note3
        NoteBySchedule.should_receive(:new).with(:note_text => @text4, :explanatory_notes_file_id => @file_id, :bill_id => @bill_id, :schedule_number => @number2, :serial_number => @serial2.to_i).and_return note4

        @file.load_notes
      end
    end
  end

end