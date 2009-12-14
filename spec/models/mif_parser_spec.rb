require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifParser do

  before(:all) do
    Act.stub!(:from_name).and_return mock('act',
      :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1',
      :legislation_url => 'http://www.legislation.gov.uk/ukpga/1996/61',
      :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61'
    )
  end

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
      Kernel.should_receive(:system).with(%Q|mif2xml < "#{mif_file}" > "#{tempfile_path}"|)

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

    it 'should move SubPara.sch ETag round SubParagraphCont.sch PdfTag' do
      @result.tr('.','-').should have_tag('SubPara-sch[id="1090960"]') do
        with_tag('SubParagraphCont-sch_PgfTag[id="7381594"]')
      end
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

    it 'should put para line start before Bpara' do
      @result.should have_tag('WordsOfEnactment[id="1003778"]') do
        with_tag('ParaLineStart[LineNum="7"]')
        with_tag('Bpara[id="1003785"]')
      end
      @result.should include('<ParaLineStart LineNum="7"></ParaLineStart><Bpara id="1003785">')
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
        with_tag('SubPara[id="1112782"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '(i)')
          end
          with_tag('SubParagraph_PgfTag[id="1112784"]') do
            with_tag('SubPara_text', :text => 'plans for dealing with any of those proposals;')
          end
        end
        with_tag('SubPara[id="1112787"]') do
          with_tag('PgfNumString') do
            with_tag('PgfNumString_1', :text => '(ii)')
          end
          with_tag('SubParagraph_PgfTag[id="1112788"]') do
            with_tag('SubPara_text')
          end
        end
      end
    end

    it 'should add in the data from the variable Regnal Title and retain &amp;' do
      @result.should have_tag('WordsOfEnactment[id="1003778"]') do
        with_tag('Bpara[id="1003785"]', :text => "Be it enacted\n by the Queen’s most Excellent Majesty, by &amp; with the advice and consent of the Lords Spiritual and Temporal, and Commons, in this present Parliament assembled, and by the authority of the same, as follows:—")
      end
    end
  end

  describe 'when parsing Equality Bill Amendment Paper MIF XML file' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('pbc0850206m.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/pbc0850206m.xml','w') {|f| f.write @result }
    end

    it 'should create XML' do
      @result.gsub('.','-').should have_tag('Amendments-Commons')
    end

    it 'should put para line start before STText' do
      @result.should include('<ParaLineStart LineNum="3"></ParaLineStart><CommitteeShorttitle id="1045605"><STText id="1053799">Equality Bill</STText></CommitteeShorttitle>')
    end
    it 'should put ParaLineStart before Number' do
      @result.should have_tag('AmedTextCommitReport_PgfTag[id="7336764"]') do
        with_tag('ParaLineStart[LineNum="10"]')
        with_tag('Number[id="1485525"]', :text => 'Clause 4,')
      end
      @result.gsub("\n",'').should include(%Q|<AmedTextCommitReport_PgfTag id="7336764"><ParaLineStart LineNum="10"></ParaLineStart><AmendmentReference Clause="4" Page="4" Line="11"><Number id="1485525">Clause <Clause_number>4</Clause_number>, </Number>|)
    end

    it 'should wrap Page/Line elements in AmendmentReference element' do
      @result.should have_tag('ParaLineStart[LineNum="29"]')
      @result.should have_tag('AmendmentReference[Page="1"][Line="21"]') do
        with_tag('Page[id="1484740"]', :text=>'Page 1,')
        with_tag('Line[id="1484754"]', :text=>'line 21,')
      end
    end

    it 'should wrap Number/Page/Line elements in AmendmentReference element' do
      @result.should have_tag('ParaLineStart[LineNum="17"]')
      @result.should have_tag('AmendmentReference[Clause="1"][Page="1"][Line="29"]') do
        with_tag('Number[id="1484880"]', :text=>'Clause 1,')
        with_tag('Page[id="1484795"]', :text=>'page 1,')
        with_tag('Line[id="1484805"]', :text=>'line 29,')
      end
    end

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

  describe 'when parsing a standing committee MIF XML file to xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('CommA20031218DummyFM7.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/CommA20031218DummyFM7.xml','w') {|f| f.write @result }
    end
    it 'should parse' do
      @result.should_not be_nil
    end

    it 'should put para line start before Shorttitle|Stageheader|Given' do
      @result.should include('<ParaLineStart LineNum="2"></ParaLineStart><Given id="1045577">given on</Given>')
      # @result.should include('<ParaLineStart LineNum="3"></ParaLineStart><Date id="1041467"><Day id="1041470">Thursday ')
      @result.should include('<ParaLineStart LineNum="4"></ParaLineStart><Stageheader id="1045600" SC="S.C.A." Stage="Committee">Standing Committee A</Stageheader>')
      @result.should include('<ParaLineStart LineNum="5"></ParaLineStart><Shorttitle id="1045605">Child Trust Funds Bill</Shorttitle>')
    end
  end

  describe 'when parsing a consideration of bill MIF XML file to xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('Tabled 27 June.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/Tabled 27 June.xml','w') {|f| f.write @result }
    end
    it 'should handle square bracketed clause number correctly' do
      @result.should include('<Number id="1043322"> [Clause <Clause_number>120</Clause_number>], </Number>')
    end
  end

  describe 'when parsing another standing committee MIF XML file to xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('CommA20031229DummyFM7.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/CommA20031229DummyFM7.xml','w') {|f| f.write @result }
    end
    it 'should parse' do
      @result.should_not be_nil
    end

    it 'should not restart _text span when it encloses an Italic span' do
      italicized = 'reduction of age of majority in respect of child trust funds'
      text = "‘(2) Section [#{italicized}] extends to Northern Ireland, but does not extend to Scotland.’."

      @result.should have_tag('SubSection[id="1051587"]') do
        with_tag('SubSection_PgfTag[id="1051592"]') do
          with_tag('SubSection_text', :text => text) do
            with_tag('Italic[id="1051590"]', :text => italicized)
          end
        end
      end
    end
  end

  describe 'when parsing a consideration of bill MIF XML file to xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('ChannelTunnel/ChannelTunnelClauses.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelClauses.xml','w') {|f| f.write @result }
    end

    it 'should not restart SubSection_text element when Citation is in text' do
      text = 'For the avoidance of doubt, nothing in sections 31 to 33 of the 1996 Act prevents the powers of the Secretary of State under section 6 of the Railways Act 2005 (c. 14) from being exercised in relation to the rail link or railway services on it.'
      @result.should have_tag('SubSection_PgfTag[id="1112746"]') do
        with_tag('SubSection_text') do
          with_tag('SubSection_text', :text => text) do
            with_tag('Citation[id="1112749"]') do
            end
          end
        end
      end
    end

    it 'should add an interpretation element' do
      @result.should have_tag('BillData') do
        with_tag('Interpretation')
      end
    end

    it 'should put definition of act name substitution in interpretation element' do
      @result.should have_tag('Interpretation') do
        with_tag('ActAbbreviation') do
          with_tag('AbbreviatedActName', :text => 'the 1996 Act')
          with_tag('Citation[Year="1996"][Chapter="(c.\x11 61)"][legislation_url="http://www.legislation.gov.uk/ukpga/1996/61"][opsi_url="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1"]', :text => 'Channel Tunnel Rail Link Act 1996 (c. 61)')
        end
      end
    end

    it 'should add ClauseText paragraph element if there are no sub paragraphs' do
      text = 'In section 56 of the 1996 Act (interpretation) in the definition of “development agreement” in subsection (1), for “or maintenance” substitute “, maintenance or operation”.'
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('ClauseText_PgfTag[id="1113675"]', :text => text) do
          with_tag('ParaLineStart[LineNum="30"]')
          # with_tag('SubSection_text', :text => text) do
            # with_tag('Citation[id="1112749"]') do
            # end
          # end
        end
      end
    end
  end

  describe 'when parsing clauses MIF XML file containing List into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_List_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_List_example.xml','w') {|f| f.write @result }
    end

    it 'should have List and ListItem outside paragraph elements' do
      @result.should  have_tag('List[id="1120732"]') do
        with_tag('ListItem[id="1120737"]') do
          with_tag('SubSection_PgfTag[id="4312655"]', :text => 'WDA is the writing-down allowance to which the person would be entitled for the chargeable period apart from this section, and')
        end
      end
    end
  end
  describe 'when parsing clauses MIF XML file containing Definition into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Definition_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Definition_example.xml','w') {|f| f.write @result }
    end

    it 'should have Definition and DefinitionItem outside paragraph elements' do
      @result.should have_tag('Definition[id="1117592"]') do
        with_tag('DefinitionList[id="1117599"]') do
          with_tag('DefinitionListItem[id="1117603"]') do
            with_tag('DefinitionList1_PgfTag[id="4315018"]', :text => '(d) a former participator to whom an amount is attributed under paragraph 2A(2) of Schedule 5 in respect of a default payment made in relation to the field in the relevant chargeable period; and')
          end
        end
      end
    end
  end

  describe 'when parsing clauses MIF XML file containing Xref into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Xref_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Xref_example.xml','w') {|f| f.write @result }
    end

    it 'should have Xref inside paragraph elements' do
      @result.should have_tag('SubSection[id="1171821"]') do
        with_tag('SubSection_PgfTag[id="1172232"]') do
          with_tag('Xref[id="1112723"][Idref="mf.0532j-1110091NC"]', :text => '(1)')
        end
      end
    end

    it 'should not have Xref_text element' do
      @result.should_not include('<Xref_text>(1)')
    end

    it 'should not end SubSection_text element at Xref element start' do
      @result.should_not include('The amendment made by subsection </SubSection_text>')
    end
  end

  describe 'when parsing clauses MIF XML file containing Sbscript into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Sbscript_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Sbscript_example.xml','w') {|f| f.write @result }
    end

    it 'should have Sbscript inside paragraph elements' do
      @result.should have_tag('ClauseTitle_PgfTag[id="4308711"]') do
        with_tag('ClauseTitle_text') do
          with_tag('Sbscript[id="4308708"]', :text => '2')
        end
      end
    end

    it 'should not have Sbscript_text element' do
      @result.should_not include('<Sbscript_text>2')
    end

    it 'should not end ClauseTitle_text element at Sbscript element start' do
      @result.should_not include('</ClauseTitle_text><Sbscript id="4308708">')
    end
  end

  describe 'when parsing clauses MIF XML file containing Char into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Char_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Char_example.xml','w') {|f| f.write @result }
    end

    it 'should have Char after ParaLineStart element' do
      @result.should include('</ParaLineStart>£0.3103')
    end

    it 'should not have Char before ParaLineStart' do
      @result.should_not include('<Para_text>£<ParaLineStart')
    end
  end

  describe 'when parsing clauses MIF XML file containing Subpara into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Subpara_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Subpara_example.xml','w') {|f| f.write @result }
    end

    it 'should have Subpara outside of paragraph element' do
      @result.should have_tag('SubPara[id="1136776"]') do
        with_tag('SubParagraph_PgfTag[id="4316053"]')
      end
    end

    it 'should have Subpara outside of paragraph and table elements' do
      @result.should have_tag('SubPara[id="1136783"]') do
        with_tag('SubParagraph_PgfTag[id="4316057"]')
        with_tag('Table[id="1137407"]')
      end
    end
  end

  describe 'when parsing clauses MIF XML file containing Interpretation into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Interpretation_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Interpretation_example.xml','w') {|f| f.write @result }
    end

    describe 'when parsing act with citation' do
      it 'should create AbbreviatedActName' do
        @result.should have_tag('AbbreviatedActName', :text=>'ALDA 1979')
      end
    end
    describe 'when parsing act abbreviation without year' do
      it 'should create AbbreviatedActName' do
        @result.should have_tag('ActAbbreviation') do
          with_tag('AbbreviatedActName', :text=>'ICTA')
        end
      end
    end
    describe 'when parsing act without citation' do
      it 'should put citation element around act name, if no citation element present' do
        @result.should have_tag('Definition_PgfTag[id="4321559"]') do
          with_tag('Definition_text') do
            with_tag('Citation[Year="1984"][Chapter="(c. 51)"]', :text => 'Capital Transfer Tax Act 1984 (c. 51)')
          end
        end
      end
      it 'should create AbbreviatedActName' do
        @result.should have_tag('ActAbbreviation') do
          with_tag('AbbreviatedActName', :text=>'CTTA 1984')
        end
      end

      it 'should create AbbreviatedActName a second time' do
        @result.should have_tag('ActAbbreviation') do
          with_tag('AbbreviatedActName', :text=>'ITA 2007')
        end
      end

      it 'should create ActAbbreviation/Citation' do
        @result.should have_tag('ActAbbreviation') do
          with_tag('Citation[Year="1984"][Chapter="(c. 51)"]', :text=>'Capital Transfer Tax Act 1984 (c. 51)')
        end
      end
      it 'should create ActAbbreviation/Citation a second time' do
        @result.should have_tag('ActAbbreviation') do
          with_tag('Citation[Year="2007"][Chapter="(c. 3)"]', :text=>'Income Tax Act 2007 (c. 3)')
        end
      end
    end
  end

  describe 'when parsing Lords clauses MIF XML file into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('DigitalEconomy/Clauses.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/Clauses.xml','w') {|f| f.write @result }
    end
  
    it 'should not start number lines inside the Prelim section' do
      @result.should have_tag('Prelim[id="1112587"]')
      @result.should have_tag('Prelim[id="1112587"]') do
        without_tag('ParaStart[LineNum]')
      end
    end
    
    it 'should create line number 1 inside the first section of the actual bill text' do
      @result.should have_tag('CrossHeading[id="1112628"]') do
        with_tag('CrossHeadingTitle[id="1113244"]', :text => 'General duties of OFCOM') do
          with_tag('ParaLineStart[LineNum="1"]')
        end
      end
    end
  end

  describe 'when parsing schedules MIF XML file into xml' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('DigitalEconomy/example/Schedules_example.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/example/Schedules_example.xml','w') {|f| f.write @result }
    end
    
    describe 'when parsing schedule' do
      it 'should create a valid Schedule structure' do
        @result.should have_tag('Schedules[id="1061327"]') do
          with_tag('SchedulesTitle[id="1061360"]')
          with_tag('Schedule[id="1059032"]') do
            with_tag('ScheduleNumber_PgfTag[id="1061375"]') do
              with_tag('PgfNumString') do
                with_tag('PgfNumString_0', :text => 'Schedule 1')
              end
            end
            with_tag('ScheduleTitle[id="1059046"]')
            with_tag('ScheduleText')
          end
        end
      end
      
      it 'should create ScheduleText' do
        @result.should have_tag('ScheduleText[id="1059046t"]')
      end
    end
  end

end