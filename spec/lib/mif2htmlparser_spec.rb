require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe MifParser do

  before do
    @parser = Mif2HtmlParser.new
  end

  describe 'when parsing longer MIF XML file to html' do
    before do
      @result = @parser.parse_xml(fixture('pbc0900206m.xml'), :html => true)
    end
    it 'should create html' do
      File.open('/Users/x/apps/uk/ex.html','w') {|f| f.write @result }
      @result.should have_tag('html')

      @result.should have_tag('div[class="Committee"][id="5166572"]') do
        with_tag('div[class="Clause_Committee"][id="2494674"]') do
          with_tag('ul[class="Sponsors"][id="2494677"]') do
            with_tag('li[class="Sponsor"][id="2494680"]', :text => 'Mr Jeremy Browne')
          end
        end
        with_tag('div[class="Amendment_Text"][id="2494721"]') do
          with_tag('div[class="SubSection"][id="7316809"]') do
            with_tag('p[class="SubSection_PgfTag"][id="7332538"]', :text => '‘(1) Aircraft flight duty is chargeable in respect of each freight and passenger aircraft on each flight undertaken by that aircraft from a destination within the UK.’.') do
              with_tag('span[class="PgfNumString"]', :text => '‘(1)')
            end
          end
        end
      end

      @result.should have_tag('div[class="Para_sch"][id="1085999"]') do
        with_tag('p[class="SubParagraph_sch_PgfTag"][id="7381591"]') do
          with_tag('span[class="PgfNumString"]') do
            with_tag('span[class="PgfNumString_1"]', :text => 'A2')
            with_tag('span[class="PgfNumString_2"]', :text => '(1)')
          end
          with_tag('span[class="SubPara_sch"]', :text => 'Paragraph 1(2) (application of Schedule) is amended as follows.')
        end
        with_tag('p[class="SubParagraphCont_sch_PgfTag"][id="7381594"]') do
          with_tag('span[class="PgfNumString"]') do
            with_tag('span[class="PgfNumString_1"]', :text => '')
            with_tag('span[class="PgfNumString_2"]', :text => '(2)')
          end
        end
      end

      @result.should have_tag('p[class="SubParagraph_sch_PgfTag"][id="7381591"]') do
        with_tag('span[class="PgfNumString"]', :text =>'A2 (1)')
        with_tag('span[class="SubPara_sch"][id="1090948"]', :text => 'Paragraph 1(2) (application of Schedule) is amended as follows.')
      end
    end
%Q|    <Committee id="5166572">
      <Clause.Committee id="2494674" Star="No">
        <Sponsors id="2494677">
          <Sponsor id="2494680">Mr Jeremy Browne</Sponsor>
        </Sponsors>
        <Amendment.Number id="2494686">4</Amendment.Number>
        <Number id="2494691">Clause 17, </Number>
        <Page id="2494701">page 11, </Page>
        <Line id="2494711">line 4, </Line>
        <Amendment.Text id="2494721">leave out from ‘substitute’ to end of line 29 and insert—
<SubSection_PgfTag id="7332538"><PgfNumString>\t‘(1)\t</PgfNumString>
            <SubSection id="7316809" Number="1" Quote="Single">Aircraft flight duty is chargeable in respect of each freight and passenger aircraft on each flight undertaken by that aircraft from a destination within the UK.’.</SubSection>
          </SubSection_PgfTag>
        </Amendment.Text>
      </Clause.Committee>
|
  end

end