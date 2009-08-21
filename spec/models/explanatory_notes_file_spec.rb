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
      @file = ExplanatoryNotesFile.new :path=>@file_path
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
      @clauses = [[@number1,@text1],[@number2,@text2]]
    end

    describe 'when getting clauses' do
      it 'should return array of clauses' do
        xml = '<Document><Clause Number="470">Clause 470</Clause>
        <Clause Number="471">Clause 471</Clause></Document>'
        @file.get_clauses(xml).should == @clauses
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
        note1 = mock('note1')
        note2 = mock('note2')
        NoteByClause.should_receive(:new).with(:note_text => @text1, :clause_number => @number1).and_return note1
        NoteByClause.should_receive(:new).with(:note_text => @text2, :clause_number => @number2).and_return note2

        @file.should_receive(:<<).with(note1)
        @file.should_receive(:<<).with(note2)
        @file.load_notes
      end
    end
  end

end