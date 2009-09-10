require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
require 'hpricot'
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
    
    it 'should handle Part 1 correctly' do
      @result.should have_tag('Part[Number="1"]') do
        with_tag('Clause[Number="1"]')
      end
    end
    
    it 'should handle Part 2 correctly' do
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
        with_tag('Chapter[Number="2"]') do
          with_tag('Clause[Number="9"]')
          with_tag('Clause[Number="10"]')
          with_tag('Clause[Number="11"]')
          with_tag('Clause[Number="12"]')
        end
        with_tag('Chapter[Number="3"]') do
          with_tag('Clause[Number="13"]')
          with_tag('Clause[Number="14"]')
          with_tag('Clause[Number="15"]')
          with_tag('Clause[Number="16"]')
          with_tag('Clause[Number="17"]')
          with_tag('Clause[Number="18"]')
        end
        with_tag('Chapter[Number="4"]') do
          with_tag('Clause[Number="19"]')
          with_tag('Clause[Number="20"]')
          with_tag('Clause[Number="21"]')
          with_tag('Clause[Number="22"]')
          with_tag('Clause[Number="23"]')
          with_tag('Clause[Number="24"]')
          with_tag('Clause[Number="25"]')
          with_tag('Clause[Number="26"]')
          with_tag('Clause[Number="27"]')
          with_tag('Clause[Number="28"]')
          with_tag('Clause[Number="29"]')
          with_tag('Clause[Number="30"]')
          with_tag('Clause[Number="31"]')
          with_tag('Clause[Number="32"]')
        end
        with_tag('Chapter[Number="5"]') do
          with_tag('Clause[Number="33"]')
        end
      end
    end
    
    it 'should create the expected number of Clauses' do
      doc = Hpricot.XML @result
      (doc/'Clause').count.should == 476
    end
  end
  
  describe 'when parsing Volume 3 of the Explanatory Notes for the Corporation Tax Bill' do
    before(:all) do
      @parser = ExplanatoryNotesParser.new
      @result = @parser.parse(RAILS_ROOT + '/spec/fixtures/CorpTax/ENs/HCB1-EN Vol 3.pdf')
      File.open(RAILS_ROOT + '/spec/fixtures/CorpTax/ENs/HCB1-EN Vol 3.xml','w') {|f| f.write @result }
    end
    
    it 'should add a BillInfo element containing Title and Version' do
      @result.should have_tag('ENData') do
        with_tag('Title', :text => 'Corporation Tax Bill')
        with_tag('Version', :text => '1')
      end
    end
    
    it 'should handle Part 9 correctly' do
      @result.should have_tag('Part[Number="9"]') do
        with_tag('Chapter[Number="1"]') do
          with_tag('Clause[Number="907"]')
        end
        with_tag('Chapter[Number="2"]') do
          with_tag('Clause[Number="908"]')
          with_tag('Clause[Number="909"]')
          with_tag('Clause[Number="910"]')
        end
        with_tag('Chapter[Number="3"]') do
          with_tag('Clause[Number="911"]')
          with_tag('Clause[Number="912"]')
          with_tag('Clause[Number="913"]')
          with_tag('Clause[Number="914"]')
          with_tag('Clause[Number="915"]')
          with_tag('Clause[Number="916"]')
          with_tag('Clause[Number="917"]')
          with_tag('Clause[Number="919"]')
          with_tag('Clause[Number="920"]')
          with_tag('Clause[Number="921"]')
          with_tag('Clause[Number="923"]')
        end
        with_tag('Chapter[Number="4"]') do
          with_tag('Clause[Number="924"]')
          with_tag('Clause[Number="925"]')
        end
        with_tag('Chapter[Number="5"]') do
          with_tag('Clause[Number="926"]')
          with_tag('Clause[Number="927"]')
          with_tag('Clause[Number="928"]')
          with_tag('Clause[Number="929"]')
          with_tag('Clause[Number="930"]')
          with_tag('Clause[Number="931"]')
        end
      end
    end
    
    it 'should have Schedule 1 thru Schedule 4' do
      @result.should have_tag('ENData') do
        with_tag('Schedule[Number="1"]')
        with_tag('Schedule[Number="2"]')
        with_tag('Schedule[Number="3"]')
        with_tag('Schedule[Number="4"]')
      end
    end
  end
  
  describe 'when parsing the Explanatory Notes for the Channel Tunnel Bill' do
    before(:all) do
      @parser = ExplanatoryNotesParser.new
      @result = @parser.parse(RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelENs.pdf')
      File.open(RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnel.xml','w') {|f| f.write @result }
    end
    
    it 'should add a BillInfo element containing Title and Version' do
      @result.should have_tag('ENData') do
        with_tag('Title', :text => 'Channel Tunnel Rail Link (Supplementary Provisions) Bill')
        with_tag('Version', :text => '4')
      end
    end
    
    it 'should have Clause 1 thru Clause 5' do
      @result.should have_tag('ENData') do
        with_tag('Clause[Number="1"]')
        with_tag('Clause[Number="2"]')
        with_tag('Clause[Number="3"]')
        with_tag('Clause[Number="4"]')
        with_tag('Clause[Number="5"]')
      end
    end
  end
  
end