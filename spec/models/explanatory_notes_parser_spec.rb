require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe ExplanatoryNotesParser do
  describe 'when parsing an Explanatory Notes file' do
    before(:all) do
      @parser = ExplanatoryNotesParser.new
    end

    it 'should call out to pdftotext' do
      pdf_file = 'HCB 1- EN Vol 1.pdf'
      tempfile_path = '/var/folders/iZ/iZnGaCLQEnyh56cGeoHraU+++TI/-Tmp-/HCB 1- EN Vol 1.pdf.txt.334.0'
      
      temp_txt_file = mock(Tempfile, :path => tempfile_path)
      Tempfile.should_receive(:new).with("#{pdf_file}.txt", RAILS_ROOT+'/tmp').and_return temp_txt_file
      temp_txt_file.should_receive(:close)
      Kernel.should_receive(:system).with(%Q|pdftotext -layout -enc UTF-8 "#{pdf_file}" "#{tempfile_path}"|)

      @parser.should_receive(:parse_txt_file).with(tempfile_path, {})
      temp_txt_file.should_receive(:delete)
      
      @parser.parse(pdf_file)
    end
  end
  
  describe 'when parsing Volume 1 of the Explanatory Notes for the Corporation Tax Bill' do
    before(:all) do
      @parser = ExplanatoryNotesParser.new
      @result = @parser.parse(RAILS_ROOT + '/spec/fixtures/CorpTax/ENs/HCB 1- EN Vol 1.pdf')
      File.open(RAILS_ROOT + '/spec/fixtures/CorpTax/ENs/HCB 1- EN Vol 1.xml','w') {|f| f.write @result }
    end
    
    it 'should add a BillInfo element containing Title and Version' do
      @result.should have_tag('ENData') do
        with_tag('Title', :text => 'Corporation Tax Bill')
        with_tag('Version', :text => '1')
      end
    end
    
    it 'should nest Clause 1 inside Part 1' do
      @result.should have_tag('Part[Number="1"]') do
        with_tag('Clause[Number="1"]')
      end
    end
    
    it 'should nest Chapter 1 and its Clauses inside Part 2' do
      @result.should have_tag('Part[Number="2"]') do
        with_tag('Chapter[Number="1"]') do
          with_tag('Clause[Number="2"]')
          with_tag('Clause[Number="3"]')
          with_tag('Clause[Number="4"]')
          with_tag('Clause[Number="5"]')
          with_tag('Clause[Number="6"]')
          with_tag('Clause[Number="7"]')
          with_tag('Clause[Number="8"]')
        end
      end
    end
  end
  
end