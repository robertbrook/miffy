require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ExplanatoryNotesFile do

  before do
    @file_path = '/path/to/notes.pdf'
  end

  describe 'when creating file' do
    def create
      ExplanatoryNotesFile.stub!(:load_notes)
      @file = ExplanatoryNotesFile.create :path=>@file_path
    end

    it 'should set name from file_path' do
      create
      @file.name.should == 'notes'
    end

    it 'should parse pdf file' do
      ExplanatoryNotesFile.stub!(:load_notes).and_return nil
      create
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

  describe 'when loading notes' do
    it 'should parse file' do
      file = ExplanatoryNotesFile.new :path => @file_path
      ExplanatoryNotesParser.should_receive(:parse).with(@file_path).and_return '<xml>'
      file.load_notes
    end
  end

end