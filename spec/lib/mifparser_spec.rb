require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifParser do

  describe 'when parsing MIF file' do
    before do
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
  end

  describe 'when parsing another long MIF XML file' do
    before(:all) do
      @parser = MifParser.new
      @result = @parser.parse_xml(fixture('pbc0850206m.mif.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/pbc0850206m.xml','w') {|f| f.write @result }
    end
    it 'should create XML' do
      @result.gsub('.','-').should have_tag('Amendments-Commons')    
    end
  end

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

      "<Document>
  <Amendments.Commons id='1020493'>
    <Head id='1033398'>
      <HeadNotice id='1033750'>
        <NoticeOfAmds id='1042951'>
          Notices of Amendments
        </NoticeOfAmds>
        <Given id='1045577'>
          given on
        </Given>
        <Date id='1041467'>
          <Day id='1041470'>
            Monday
          </Day>
          <Date.text id='1041477'>
            1 June 2009
          </Date.text>
        </Date>
        <Stageheader id='1045600'>
          Public Bill Committee
        </Stageheader>
        <CommitteeShorttitle id='1045605'>
          <STText id='1053525'>
            Local Democracy, Economic Development and Construction Bill
          </STText>
          <STHouse id='5229516'>
             [
            <STLords id='5229520'>
              Lords
            </STLords>
            ]
          </STHouse>
        </CommitteeShorttitle>
      </HeadNotice>
    </Head>
    <Committee id='1150928'>
      <NewClause.Committee id='1497582'>
        <New_C_STitle>
          <PgfNumString>
            \\t
          </PgfNumString>
          <ClauseTitle id='1497590'>
            Award of construction projects
          </ClauseTitle>
        </New_C_STitle>
        <Sponsors id='1497599'>
          <Sponsor id='1497603'>
            Ms Sally Keeble
          </Sponsor>
          <Sponsor id='1497609'>
            Ms Dari Taylor
          </Sponsor>
          <Sponsor id='1497618'>
            Joan Walley
          </Sponsor>
        </Sponsors>
        <Amendment.Number id='1497632'>
          NC1
        </Amendment.Number>
        <Move id='1497648'>
          To move the following Clause:—
        </Move>
        <ClauseText id='1497659'>
          ‘In considering the award of a contract in accordance with the
          Housing Grant, Construction and Regeneration Act 1996 (c. 53), a local
          authority may have regard to—
          <Paragraph>
            <PgfNumString>
              \\t(a)\\t
            </PgfNumString>
            <Para id='1497669'>
              their functions under section 66 of the Local Democracy, Economic
              Development and Construction Act 2009 (local authority economic
              assessment); and
            </Para>
          </Paragraph>
          <Paragraph>
            <PgfNumString>
              \\t(b)\\t
            </PgfNumString>
            <Para id='1497676'>
              the desirability of maintaining a diverse range of contractors in
              its local authority area.’.
            </Para>
          </Paragraph>
        </ClauseText>
      </NewClause.Committee>
    </Committee>
  </Amendments.Commons>
</Document>"

    end
  end

end