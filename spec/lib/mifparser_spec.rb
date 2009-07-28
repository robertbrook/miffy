require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifParser do
# =begin
  describe 'when parsing MIF file' do
    before(:all) do
      @parser = MifParser.new
    end

    it 'should call out to mif2xml' do
      mif_file = 'pbc0930106a.mif'
      tempfile_path = '/var/folders/iZ/iZnGaCLQEnyh56cGeoHraU+++TI/-Tmp-/pbc0930106a.mif.xml.334.0'

      temp_xml_file = mock(Tempfile, :path => tempfile_path)
      Tempfile.should_receive(:new).with("#{mif_file}.xml", RAILS_ROOT+'/tmp').and_return temp_xml_file
      temp_xml_file.should_receive(:close)
      Kernel.should_receive(:system).with("mif2xml < #{mif_file} > #{tempfile_path}")

      @parser.should_receive(:parse_xml_file).with(tempfile_path, {})
      temp_xml_file.should_receive(:delete)

      @parser.parse(mif_file)
    end
  end

  describe 'when parsing longer MIF XML file to xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('pbc0900206m.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/pbc0900206m.xml','w') {|f| f.write @result }
    end
    
    it 'should not add a BillTitle element' do
      @result.should_not have_tag('BillTitle', :text => 'Law Commission Bill [HL]')
    end

    it 'should add element around text in mixed element/text situation' do
      @result.should have_tag('SubSection[id="1151133"]') do
        with_tag('SubSection1_PgfTag[id="7382611"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '‘(1)')
          end
          with_tag('SubSection_text', :text=> 'If, when determining the liability of a person to taxation, duty or similar charge due under statute in the United Kingdom, it shall be estimated that a step or steps have been included in a transaction giving rise to that liability or to any claim for an allowance, deduction or relief, with such steps having been included for the sole or one of the main purposes of securing a reduction in that liability to taxation, deduction or similar charge with no other material economic purpose for the inclusion of such a step being capable of demonstration by the taxpayer, then, subject to the sole exception that the step or steps in question are specifically permitted under the terms of any legislation promoted for the specific purpose of permitting such use, such step or steps shall be ignored when calculating the resulting liability to taxation, duty or similar charge.')
        end
      end
    end
    
    it 'should move Amendment.Text ETag round AmedTextCommitReport PdfTag' do
      @result.tr('.','-').should have_tag('Amendment-Text[id="1047173"]') do
        with_tag('AmedTextCommitReport_PgfTag[id="7381581"]') do
          with_tag('Number[id="1046333"]', :text => 'Schedule 8,') do
            with_tag('Schedule_number', :text => '8')
          end
          with_tag('Page[id="1046348"]', :text => 'page 101,') do
            with_tag('page_number', :text => '101')
          end
        end
        with_tag('Para-sch[id="1083782"]')
      end
    end

    it 'should move Amendment.Number ETag round AmendmentNumber PgfTag' do
      # line below should not be hardcoded
      # File.open('/Users/x/apps/uk/ex.xml','w') {|f| f.write @result }
      @result.tr('.','-').should have_tag('Amendment-Number[id="2494686"]') do
        with_tag('AmendmentNumber_PgfTag', :text => '4')
      end
    end

    it 'should move SubSection ETag round SubSection PgfTag' do
      @result.tr('.','-').should have_tag('SubSection[id="1489118"]') do
        with_tag('SubSection_PgfTag[id="7381365"]')
      end
    end

    it 'should set id on PgfTag paragraphs' do
      @result.gsub('.','-').should have_tag('SubParagraph-sch_PgfTag[id="7381591"]')
    end

    it 'should set id on ETag paragraphs' do
      @result.gsub('.','-').should have_tag('Para-sch[id="1085999"]')
    end

    it 'should set attributes on ETag paragraphs' do
      @result.gsub('.','-').should have_tag('Para-sch[Major_Number_Only="A2"]')
      @result.gsub('.','-').should have_tag('Para-sch[Number="A"]')
      @result.gsub('.','-').should have_tag('Para-sch[Letter="2"]')
    end
  end

  describe 'when parsing Clauses MIF XML file' do
    before(:all) do      
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('Clauses.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/Clauses.xml','w') {|f| f.write @result }
    end
    
    it 'should create XML' do
      @result.gsub('.','-').should have_tag('Clause[id="1093880"]') do
        with_tag('ClauseTitle_PgfTag[id="1112748"]')
      end
    end
    
    it 'should put page start inside clauses element around page content' do
      @result.should have_tag('Clauses[id="1112573"]') do
        with_tag('PageStart[id="996720"][PageType="BodyPage"][PageNum="1"]')
      end
    end
    
    it 'should add a BillTitle element' do
      @result.should have_tag('BillTitle', :text => 'Law Commission Bill [HL]')
    end
    
    it 'should add a Frame element' do
      @result.gsub('.','-').should have_tag('FrameData[id="1112726"]') do
        with_tag('Dropcap[id="1003796"]', :text => 'B')
      end
    end
    
    it 'should add a Footer element containing the BillPrintNumber and the BillSessionNumber' do
      @result.should have_tag('Footer') do
        with_tag('BillPrintNumber', :text => 'Bill 101')
        with_tag('BillSessionNumber', :text => '54/4')
      end
    end

    it 'should put SubSection_text element around Bold element' do
      text = 'Nothing in this Act shall impose any charge on the people or on public funds, or vary the amount or incidence of or otherwise alter any such charge in any manner, or affect the assessment, levying, administration or application of any money raised by any such charge'
      
      @result.gsub('.','-').should have_tag('SubSection_PgfTag[id="1113230"]') do
        with_tag('SubSection_text', :text => "#{text}-") do
          with_tag('Bold[id="1112372"]', :text => text)
        end
      end
    end
      
    it 'should put Para etag around _Paragraph_PgfTag and multiple _SubParagraph_PgfTag elements' do
      @result.gsub('.','-').gsub('<_','<').gsub('</_','</').should have_tag('Para[id="1111739"]') do
        with_tag('Paragraph_PgfTag[id="1112779"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '(b)')
          end
          with_tag('Para_text', :text => 'the Law Commission proposals that have not been implemented (in whole or in part) as at the end of the year, including—')
        end
        with_tag('SubParagraph_PgfTag[id="1112784"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '(i)')
          end
          with_tag('SubPara[id="1112782"]') do
            with_tag('SubPara_text', :text => 'plans for dealing with any of those proposals;')
          end
        end
        with_tag('SubParagraph_PgfTag[id="1112788"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '(ii)')
          end
          with_tag('SubPara[id="1112787"]') do
            with_tag('SubPara_text')
          end
        end
      end
    end
    
    it 'should add in the data from the variable Regnal Title' do
      @result.should have_tag('WordsOfEnactment[id="1003778"]') do
        with_tag('Bpara[id="1003785"]', :text => "Be it enacted\n by the Queen’s most Excellent Majesty, by and with the advice and consent of the Lords Spiritual and Temporal, and Commons, in this present Parliament assembled, and by the authority of the same, as follows:—")
      end
    end
  end

  describe 'when parsing Cover MIF XML file' do
    before(:all) do      
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('Cover.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/Cover.xml','w') {|f| f.write @result }
    end
    
    it 'should create XML' do
      @result.should have_tag('Cover[id="1000723"]') do
        with_tag('Rubric[id="1002024"]')
      end
    end
    
    it 'should add a BillTitle element' do
      @result.should have_tag('BillTitle', :text => 'Law Commission Bill [HL]')
    end
  end
# =end
  describe 'when parsing Equality Bill Amendment Paper MIF XML file' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('pbc0850206m.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/pbc0850206m.xml','w') {|f| f.write @result }
    end
    
    it 'should create XML' do
      @result.gsub('.','-').should have_tag('Amendments-Commons')    
    end
    
    it 'should put ParaLineStart before Number' do
      @result.should have_tag('AmedTextCommitReport_PgfTag[id="7336764"]') do
        with_tag('ParaLineStart[LineNum="10"]')
        with_tag('Number[id="1485525"]', :text => 'Clause 4,')
      end
      @result.gsub("\n",'').should include(%Q|<AmedTextCommitReport_PgfTag id="7336764"><ParaLineStart LineNum="10"></ParaLineStart><Number id="1485525">Clause <Clause_number>4</Clause_number>, </Number>|)
    end
=begin 
    it 'should wrap Number/Page/Line elements in AmendmentReference element' do
      @result.should have_tag('AmendmentReference[Clause="1"][Page="1"][Line="29"]') do
        with_tag('Number[id="1484880"]', :text=>'Clause 1,')
        with_tag('Page[id="1484795"]', :text=>'page 1,')
        with_tag('Line[id="1484805"]', :text=>'line 29,')
      end
    end
=end    
    it 'should put PageStart before Motion element' do
      @result.should have_tag('PageStart[id="5184234"][PageType="BodyPage"][PageNum="29"]', :text => 'Page 29')            
      @result.gsub("\n",'').should include(%Q|<PageStart id="5184234" PageType="BodyPage" PageNum="29">Page 29</PageStart><Motion id="6541538">|)
    end
    
    it 'should put PageStart outside of Para if at start of Para' do
      @result.should have_tag('PageStart[id="7338433"][PageType="BodyPage"][PageNum="33"]', :text => 'Page 33')      
      @result.should have_tag('Para[id="1493569"]') do
        with_tag('Paragraph_PgfTag[id="7337702"]') do
          with_tag('PgfNumString') { with_tag('PgfNumString_1', :text =>'(b)') }
          with_tag('Para_text', :text => 'evidence that the regulations will enable the better performance by public authorities of the duty imposed by subsection (1).’.')
        end
      end
      @result.gsub("\n",'').should include(%Q|<PageStart id="7338433" PageType="BodyPage" PageNum="33">Page 33</PageStart><Para id="1493569">|)
    end
    
    it 'should add element around text in mixed element/text situation' do
      @result.should have_tag('Resolution[id="1070180"]') do
        with_tag('ResolutionText[id="1070211"]') do
          with_tag('ResolutionText_text', :text => 'That—')
        end
      end
    end
    
    it 'should add TableData, Row, CellH and Cell elements inside the Table element' do
      @result.should have_tag('Table[id="6540480"]') do
        with_tag('TableData[id="7336058"]') do
          with_tag('Row[id="6540534"]') do
            with_tag('CellH[id="6540535"]', :class => 'first', :text => 'Date')
            with_tag('CellH[id="6540536"]', :class => nil, :text => 'Time')
            with_tag('CellH[id="6540537"]', :class => nil, :text => 'Witness')
          end
          with_tag('Row[id="6540538"]') do
            with_tag('Cell[id="6540539"]', :class => 'first', :text => 'Tuesday 2 June')
            with_tag('Cell[id="6540540"]', :class => nil, :text => 'Until no later than 12 noon')
            with_tag('Cell[id="6540541"]', :class => nil, :text => 'Equality and Diversity Forum/nEquality and Human Rights  Commission/nEmployment Tribunals Service')
          end
        end
      end
    end    
  end
# =begin

  describe 'when parsing MIF XML file' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('pbc0930106a.mif.xml'))
      # file referenced below not checked in?
      File.open(RAILS_ROOT + '/spec/fixtures/pbc0930106a.xml','w') {|f| f.write @result }
    end

    it 'should remove instructions text' do
      @result.should_not include('Use the following fragment to insert an amendment line number')
      @result.should_not include('REISSUE')
      @result.should_not include('continued,')
      @result.should_not include('House of CommonsHouse of Commons')
    end

    it 'should make ETags into elements' do
      @result.gsub('.','-').should have_tag('Amendments-Commons') do
        with_tag('Head') do
          with_tag('HeadNotice') do
            with_tag('NoticeOfAmds', :text => 'Notices of Amendments')
            with_tag('Given', :text => 'given on')
            with_tag('Date', :text => 'Monday 1 June 2009') do
              with_tag('Day', :text => 'Monday')
              with_tag('Date-text', :text => '1 June 2009')
            end
            with_tag('Stageheader', :text => 'Public Bill Committee' )
            with_tag('CommitteeShorttitle', :text => 'Local Democracy, Economic Development and Construction Bill [Lords]') do
              with_tag('STText', :text => 'Local Democracy, Economic Development and Construction Bill')
              with_tag('STHouse', :text => '[Lords]')
            end
          end
        end
      end
    end
  end
# =end
end