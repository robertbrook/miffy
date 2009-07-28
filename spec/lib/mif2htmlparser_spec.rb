require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe MifParser do
  describe 'when formatting certain spans' do
    def check span, ending
      Mif2HtmlParser.format_haml("#{span}\n").should == "#{span}#{ending}\n"
    end
    it 'should close whitespace following span' do
      check "%span#1003816.Letter", "<>"
      check "%span#1112726.FrameData", "<>"
      check "%span#1003796.Dropcap", "<>"
      check "%span#1003802.SmallCaps", "<"      
    end
    
    it 'should expand clause number span' do
      text = %Q|
            %span#1485163.Number
              %a{ :name => "page29-line24" }
              Clause
              %span.Clause_number
                1
              ,|
      Mif2HtmlParser.format_haml(text).should == %Q|
            %a{ :name => "page29-line24" }<
            %span#1485163.Number<
              Clause <span class="Clause_number">1</span>,|
    end
  end
end

describe MifParser do

  def parser
    parser = Mif2HtmlParser.new
    parser.stub!(:find_act_url).and_return nil
    parser
  end

  describe 'when parsing Clauses MIF XML file to haml' do
    before(:all) do
      @result = parser.parse_xml(fixture('clauses.xml'), :format => :haml)
    end
    it 'should not put Para span before _Paragraph_PgfTag paragraph' do
      @result.should_not include("%span#1112895.Para")      
      @result.should include("#1112895.Para")  
    end
    it 'should have an anchor name marking a clause start' do
      @result.should include(%Q|%span.PgfNumString_1<>\n                  %a#clause_LC1{ :name => \"clause1\", :href => \"#clause1\" }<>\n                    1\n|)
    end
  end

  describe 'when parsing another MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('pbc0850206m.xml'), :format => :html)
    end
    it 'should create html' do
      # File.open('/Users/x/apps/uk/ex.html','w') {|f| f.write @result }
      @result.should have_tag('html')
      @result.should have_tag('div[class="Resolution"][id="1070180"]') do
        with_tag('div[class="ResolutionHead"][id="1070184"]') do
          with_tag('p[class="OrderHeading_PgfTag"][id="7335998"]', :text => 'Resolution of the Programming Sub-Committee')
        end
      end
      
      @result.should have_tag('table[class="TableData"][id="7336058"]') do
        with_tag('tr[class="Row"][id="6540534"]') do
          with_tag('th[class="CellH first"][id="6540535"]', :text => 'Date')
          with_tag('th[class="CellH"][id="6540536"]', :text => 'Time')
          with_tag('th[class="CellH"][id="6540537"]', :text => 'Witness')
        end
        with_tag('tr[class="Row"][id="6540538"]') do
          with_tag('td[class="Cell first"][id="6540539"]', :text => 'Tuesday 2 June')
          with_tag('td[class="Cell"][id="6540540"]', :text => 'Until no later than 12 noon')
          with_tag('td[class="Cell"][id="6540541"]', :html => 'Equality and Diversity Forum<br />Equality and Human Rights  Commission<br />Employment Tribunals Service')
        end
      end
    end
    
    # it 'should make clause/page/line reference a hyperlink' do
      # @result.should have_tag('') do
      # end
    # end
  end
  
  describe 'when parsing longer MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('pbc0900206m.xml'), :format => :html)
    end
    it 'should create html' do
      # File.open('/Users/x/apps/uk/ex.html','w') {|f| f.write @result }
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