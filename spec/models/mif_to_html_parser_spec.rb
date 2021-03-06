require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe MifToHtmlParser do

  before(:all) do
    Act.stub!(:from_name).and_return nil
  end

  def parser url=nil, other_url=nil
    parser = MifToHtmlParser.new
    parser.stub!(:find_act_url).and_return url
    parser.stub!(:find_bill_url).and_return other_url
    parser
  end

  describe 'when parsing Clauses MIF XML file to text' do
    before(:all) do
      @result = parser.parse_xml(fixture('clauses.xml'), :format => :text)
    end
    it 'should not have any tags in output' do
      @result.should include('Be it enacted by the Queen’s most Excellent Majesty, by &amp; with the advice and
consent of the Lords Spiritual and Temporal, and Commons, in this present
Parliament assembled, and by the authority of the same, as follows:—')
    end
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

    it 'should have toggle link around clause title' do
      @result.should include(%Q|= link_to_function "Reports on implementation of Law Commission proposals", "$('#1112590').toggle();imgswap('1112590_img')"|)
    end

    it 'should have clause-page-line and page-line anchors' do
      @result.should include('%a{ :name => "page1-line10" }')
      @result.should include('%a{ :name => "page1-line15" }')

      @result.should include('%a{ :name => "clause1-page1-line10" }')
      @result.should include('%a{ :name => "clause1-page1-line15" }')
    end
  end

  describe 'when parsing another MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('pbc0850206m.xml'), :format => :html)
    end
    it 'should create html' do
      @result.should have_tag('html')
      @result.should have_tag('div[class="Resolution"][id="1070180"]') do
        with_tag('div[class="ResolutionHead"][id="1070184"]') do
          with_tag('p[class="OrderHeading_PgfTag"][id="7335998"]', :text => 'Resolution of the Programming Sub-Committee')
        end
      end

      @result.should have_tag('table[class="TableData"][id="7336058"]') do
        with_tag('tr[id="6540534"]') do
          with_tag('th[id="6540535"]', :text => 'Date')
          with_tag('th[id="6540536"]', :text => 'Time')
          with_tag('th[id="6540537"]', :text => 'Witness')
        end
        with_tag('tr[class="Row"][id="6540538"]') do
          with_tag('td[id="6540539"]', :text => 'Tuesday 2 June')
          with_tag('td[id="6540540"]', :text => 'Until no later than 12 noon')
          with_tag('td[id="6540541"]', :html => 'Equality and Diversity Forum<br />Equality and Human Rights  Commission<br />Employment Tribunals Service')
        end
      end
    end

    it 'should put anchor before span' do
      @result.should have_tag('a[name="page29-line24"]')
      @result.should have_tag('span[id="1485163"][class="Number"]', :text => 'Clause 1,') do
        with_tag('span[class="Clause_number"]', :text=>'1')
      end
    end

    it 'should make clause/page/line reference a hyperlink'
  end

  describe 'when parsing longer MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('pbc0900206m.xml'), :format => :html)
    end
    it 'should create html' do
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
        with_tag('div[class="SubPara_sch"]') do
          with_tag('p[class="SubParagraph_sch_PgfTag"][id="7381591"]') do
            with_tag('span[class="PgfNumString"]') do
              with_tag('span[class="PgfNumString_1"]', :text => 'A2')
              with_tag('span[class="PgfNumString_2"]', :text => '(1)')
            end
            with_tag('span[class="SubPara_sch_text"]', :text => 'Paragraph 1(2) (application of Schedule) is amended as follows.')
          end
        end
        with_tag('p[class="SubParagraphCont_sch_PgfTag"][id="7381594"]') do
          with_tag('span[class="PgfNumString"]') do
            with_tag('span[class="PgfNumString_1"]', :text => '&nbsp;')
            with_tag('span[class="PgfNumString_2"]', :text => '(2)')
          end
        end
      end

      @result.should have_tag('div[class="SubPara_sch"][id="1090948"]') do
        with_tag('p[class="SubParagraph_sch_PgfTag"][id="7381591"]') do
          with_tag('span[class="PgfNumString"]', :text =>'A2 (1)')
          with_tag('span[class="SubPara_sch_text"]', :text => 'Paragraph 1(2) (application of Schedule) is amended as follows.')
        end
      end
    end
  end

  describe 'when parsing a standing committee MIF XML file to html' do
    before(:all) do
      @url = 'http://www.opsi.gov.uk/acts/acts1992/ukpga_19920004_en_1'
      @result = parser(@url,nil).parse_xml(fixture('CommA20031218DummyFM7.xml'), :format => :html)
    end
    it 'should put new line anchor outside of citation link' do
      @result.should have_tag('p[id="1055416"][class="Paragraph_PgfTag"]') do
        with_tag('span[class="Para_text"]') do
          with_tag('a[id="1055415"][class="Citation"][href="' + @url + '"]', :text => 'Social Security Contributions and Benefits Act 1992 (c. 4)')
          with_tag('a[name="page14-line7"]')
        end
      end

      @result.should_not include('<a id="1055415" href="' + @url + '" class="Citation">Social Security Contributions and <a name="page14-line7"></a>Benefits Act 1992 (c. 4)</a>')

      @result.should include('<a id="1055415" href="' + @url + '" class="Citation" title="Social Security Contributions and Benefits Act 1992 (c. 4)">Social Security Contributions and <br />Benefits Act 1992 (c. 4)</a><a name="page14-line7"></a>')
    end

    it 'should put new line anchor outside of Shorttitle link' do
      @result.should include('<a name="page1-line5"></a><div id="1045605" class="Shorttitle">Child Trust Funds Bill</div>')
    end
  end


  describe 'when parsing another standing committee MIF XML file to html' do
    before(:all) do
      @url = 'http://www.opsi.gov.uk/acts/acts1992/ukpga_19920004_en_1'
      @result = parser(@url).parse_xml(fixture('CommA20031229DummyFM7.xml'), :format => :html)
      File.open(RAILS_ROOT + '/spec/fixtures/CommA20031229DummyFM7.html','w') {|f| f.write @result }
    end

    it 'should add a br when there is a new line in a Amendment_Text_text span, and make SoftHyphen a hyphen' do
      @result.should include('<span class="Amendment_Text_text">after second ‘the’, insert ‘first day of the month that in-<br /><a name="page5-line18"></a>cludes the’.</span></p>')
    end

    it 'should add a br when new line occurs in an Italic span' do
      @result.should include('<span class="Italic" id="1051524">reduction of age of <br /><a name="page5-line35"></a>majority in respect of child trust funds</span>')
    end

    it 'should not restart _text span when it encloses an Italic span' do
      italicized = 'reduction of age of majority in respect of child trust funds'
      text = "‘(2) Section [#{italicized}] extends to Northern Ireland, but does not extend to Scotland.’."

      @result.should have_tag('div[class="SubSection"][id="1051587"]') do
        with_tag('p[class="SubSection_PgfTag"][id="1051592"]') do
          with_tag('span[class="SubSection_text"]', :text => text) do
            with_tag('span[class="Italic"][id="1051590"]', :text => italicized)
          end
        end
      end
    end
  end

  describe 'when parsing a bill with citation to act' do
    before(:all) do
      @url = 'http://www.opsi.gov.uk/acts/acts2005/ukpga_20050014_en_14'
      @result = parser(@url).parse_xml(fixture('ChannelTunnel/ChannelTunnelClauses.act.xml'), :format => :haml)
      File.open(RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelClauses.haml','w') {|f| f.write @result }
    end

    it 'should put space after page anchor when citation is at start of line' do
      @result.should include('\ from being exercised in relation to the rail link or railway services on it.')
    end

    it 'should put line start anchor outside of section reference anchor' do
      @result.should include('
                    section 6 of the Railways Act 2005
                    %br
                    (c. 14)
                  %a{ :name => "page1-line12" }<>
                  %a{ :name => "clause1-page1-line12" }<>')
    end
  end

  describe 'when parsing a Lords Clauses MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('DigitalEconomy/Clauses.act.xml'), :format => :html)
    end
    
    it 'should create html' do
      @result.should have_tag('html')
      @result.should have_tag('div[class="Clauses"][id="1112573"]')
    end
    
    it 'should not create a named anchor inside Prelim section' do
      @result.should have_tag('div[class="Prelim"][id="1112587"]') do
        with_tag('div[class="ABillTo"][id="1003906"]') do
          with_tag('div[class="Abt1"][id="1003909"]') do
            without_tag('a[name]')
          end
        end
      end
    end
    
    it 'should create line break when line break is between xrefs' do
      @result.should include('<a id="1144999" class="Xref" href="#clause13-amendment-clause124J-2-a" title="Clause 13, Amendment Clause 124J Subsection 2 paragraph a">(a)</a><br /><a name="page15-line7"></a><a name="clause13-page15-line7"></a>or <a id="1145003" class="Xref" href="#clause13-amendment-clause124J-2-c" title="Clause 13, Amendment Clause 124J Subsection 2 paragraph c">(c)</a>')
    end
    
    it 'should create a named anchor for page1-line1 inside the first CrossHeading section' do
      @result.should have_tag('div[class="CrossHeading"][id="1112628"]') do
        with_tag('div[class="CrossHeadingTitle"][id="1113244"]') do
          with_tag('a[name="page1-line1"]')
        end
      end
    end
  end

  describe 'when parsing Schedules MIF XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('DigitalEconomy/example/Schedules_example.xml'), :format => :html)
    end
    
    it 'should create html' do
      @result.should have_tag('html')
      @result.should have_tag('div[class="Schedules"][id="1061327"]') do
        with_tag('div[class="SchedulesTitle"][id="1061360"]')
        with_tag('div[class="Schedule"][id="1059032"]') do
          with_tag('p[class="ScheduleNumber_PgfTag"][id="1061375"]') do
            with_tag('span[class="PgfNumString"]') do
              with_tag('span[class=PgfNumString_0]', :text => 'Schedule 1')
            end
          end
          with_tag('div[class="SectionReference"][id="1059060"]')
          with_tag('div[class="ScheduleTitle"][id="1059046"]')
          with_tag('div[class="ScheduleText"][id="1059046t"]') do
            with_tag('div[class="Para_sch"][id="1059118"]')
          end
        end
      end
    end

    it 'should put anchor before span' do
      @result.should have_tag('p[class="SubSubParagraph_sch_PgfTag"][id="1202341"]') do
        with_tag('a[name="page53-line1"]')
        with_tag('span[class="SubSubPara_sch_text"]', :text => 'after “Act” insert—')
      end
    end
  end
  
end