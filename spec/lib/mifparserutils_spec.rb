require File.dirname(__FILE__) + '/../spec_helper.rb'

class MifParserUtilsExample
  include MifParserUtils
end

describe MifParserUtils do
  before :all do
    @utils = MifParserUtilsExample.new
  end

  describe 'when preprocessing html' do
    it 'should preprocess first anchor element' do
      text = "the <a rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1'>Video <br />Recordings Act 1984</a>; to make provision about public lending right in relation"
      expected = "the&nbsp;<a style='trim_outside_whitespace' rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1'>Video <br />Recordings Act 1984</a>; to make provision about public lending right in relation"
      @utils.preprocess(text).should == expected
    end

    it 'should preprocess second anchor element' do
      text = "the <a rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1'>Video <br />Recordings Act 1984</a>; to make provision about public lending right in relation to <a rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840040_en_1'>Another Recordings Act 1984</a>; "
      expected = "the&nbsp;<a style='trim_outside_whitespace' rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1'>Video <br />Recordings Act 1984</a>; to make provision about public lending right in relation to&nbsp;<a style='trim_outside_whitespace' rel='cite' href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840040_en_1'>Another Recordings Act 1984</a>; "
      @utils.preprocess(text).should == expected
    end

    it 'should preprocess the correct anchor element' do
      text = %Q|sections <a id="1139029" class="Xref" href="#clause4-amendment-clause124A">124A</a> and <a id="1139041" class="Xref" href="#clause5-amendment-clause124B">124B</a> are in force but for which <br /><a name="page9-line9"></a><a name="clause7-page9-line9"></a>there is no approved initial obligations code under section <a id="1138942" class="Xref" href="#clause6-amendment-clause124C">124C</a>, <br />|
      expected = %Q|sections <a id="1139029" class="Xref" href="#clause4-amendment-clause124A">124A</a> and <a id="1139041" class="Xref" href="#clause5-amendment-clause124B">124B</a> are in force but for which <br /><a name="page9-line9"></a><a name="clause7-page9-line9"></a>there is no approved initial obligations code under section&nbsp;<a style='trim_outside_whitespace' id="1138942" class="Xref" href="#clause6-amendment-clause124C">124C</a>, <br />|
      @utils.preprocess(text).should == expected
    end

    it 'should preprocess the correct span element' do
      text = %Q|sections <span id="1139029" class="Xref">124A</span> and <span id="1139041" class="Xref">124B</span> are in force but for which <br /><span name="page9-line9"></span><span name="clause7-page9-line9"></span>there is no approved initial obligations code under section <span id="1138942" class="Xref">124C</span>, <br />|
      expected = %Q|sections <span id="1139029" class="Xref">124A</span> and <span id="1139041" class="Xref">124B</span> are in force but for which <br /><span name="page9-line9"></span><span name="clause7-page9-line9"></span>there is no approved initial obligations code under section&nbsp;<span style='trim_outside_whitespace' id="1138942" class="Xref">124C</span>, <br />|
      @utils.preprocess(text).should == expected
    end

    it 'should preprocess first span element' do
      text = "the <span class='Xref'>Video <br />Recordings Act 1984</span>; to make provision about public lending right in relation"
      expected = "the&nbsp;<span style='trim_outside_whitespace' class='Xref'>Video <br />Recordings Act 1984</span>; to make provision about public lending right in relation"
      @utils.preprocess(text).should == expected
    end

    it 'should preprocess second span element' do
      text = "the <span class='Xref'>Video <br />Recordings Act 1984</span>; to make provision about public lending right in relation to <span class='Xref'>Another Recordings Act 1984</span>; "
      expected = "the&nbsp;<span style='trim_outside_whitespace' class='Xref'>Video <br />Recordings Act 1984</span>; to make provision about public lending right in relation to&nbsp;<span style='trim_outside_whitespace' class='Xref'>Another Recordings Act 1984</span>; "
      @utils.preprocess(text).should == expected
    end
    
    it 'should not crunch whitespace after element if word is after element' do
      text =     'the <a href="http://www.opsi.gov.uk/acts/acts2003/ukpga_20030021_en_1.htm" rel="cite">Communications Act 2003</a> (electronic'
      @utils.preprocess(text).should == text
    end

    it 'should not crunch whitespace after element if word is after element' do
      text =     'the <a href="http://www.opsi.gov.uk/acts/acts2003/ukpga_20030021_en_1.htm" rel="cite">Communications Act 2003</a> (electronic <br /><a name="page2-line27"></a><a name="clause2-page2-line27"></a>communications'
      @utils.preprocess(text).should == text
    end
  end
    
  describe 'when postprocessing haml' do

    it 'should trim outside whitespace when trim_outside_whitespace style on anchor element' do
      haml =     '%a{ :href => "http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1", :rel => "cite", :style => "trim_outside_whitespace" }'
      expected = '%a{ :href => "http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1", :rel => "cite" }><'
      @utils.format_haml("#{haml}\n").should == "#{expected}\n"
    end
  end
  
  describe 'when postprocessing html' do
    it 'should replace &nbsp; before anchor with " "' do
      html = "the regulation of the use of the electromagnetic spectrum; to amend the&nbsp;<a href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1' rel='cite'>Video"
      expected = "the regulation of the use of the electromagnetic spectrum; to amend the <a href='http://www.opsi.gov.uk/RevisedStatutes/Acts/ukpga/1984/cukpga_19840039_en_1' rel='cite'>Video"
      @utils.postprocess(html).should == expected
    end
    it 'should replace &nbsp; before span with " "' do
      html = "the regulation of the use of the electromagnetic spectrum; to amend the&nbsp;<span class='Xref'>Video"
      expected = "the regulation of the use of the electromagnetic spectrum; to amend the <span class='Xref'>Video"
      @utils.postprocess(html).should == expected
    end
  end
  

  describe 'when formatting certain spans' do
    def check haml, ending
      @utils.format_haml("#{haml}\n").should == "#{haml}#{ending}\n"
    end

    it 'should close whitespace following span' do
      check "%span#1003816.Letter", "<>"
      check "%span#1112726.FrameData", "<>"
      check "%span#1003796.Dropcap", "<>"
      check "%span#1003802.SmallCaps", "<>"
      check "%span#1003802.SmallCaps", "<>"
      check ".BillTitle", "<"
      check "%a{ :href => 'http://services.parliament.uk/bills/2008-09/lawcommission.html' }", "<"
      check '%a{ :name => "page27-line3" }', '<>'
      check "%span#1053799.STText", '<'
      check "#1045577.Given", '<'
      check "#1045600.Stageheader", '<'
      check "#1045605.Shorttitle", '<'
      check "#1045605.Xref", '<'
    end

    it 'should turn AmendmentReference into a link_to call' do
      text = '%a.AmendmentReference{ :href => "#clause1-page1-line29" }<'
      clauses_file = '/Users/x/apps/uk/miffy/spec/fixtures/Finance_Clauses.xml'
      @utils.format_haml(text, clauses_file).should ==
        '%a.AmendmentReference{ :href => "http://localhost:3000/convert?file=' + clauses_file + '#clause1-page1-line29" }<'
    end

    it 'should collapse whitespace around quoted act link' do
      text = %Q|              In this Act, “
              %a{ :href => "http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1", :rel => "cite", :resource => "http://www.legislation.gov.uk/ukpga/1996/61" }<
                the 1996 Act
              ” means the|
      @utils.format_haml(text).should == %Q|              In this Act, “
              %a{ :href => "http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1", :rel => "cite", :resource => "http://www.legislation.gov.uk/ukpga/1996/61" }<>
                the 1996 Act
              ” means the|
    end

    it 'should have toggle link around clause title' do
      text = %Q|
          %span.ClauseTitle_text<
            Reports on implementation of Law Commission proposals
      #1112590.ClauseText
|
      @utils.format_haml(text).should == %Q|
          = link_to_function '<img alt="" id="1112590_img" src="/images/down-arrow.png">', "$('#1112590').toggle();imgswap('1112590_img')"
          %span.ClauseTitle_text<
            = link_to_function "Reports on implementation of Law Commission proposals", "$('#1112590').toggle();imgswap('1112590_img')"
      #1112590.ClauseText
|
    end

    it 'should have toggle link around clause title when explanatory note present' do
      text = %Q|
          %span.ClauseTitle_text<
            Reports on implementation of Law Commission proposals
      #1112590en.ClauseTextWithExplanatoryNote
|
      @utils.format_haml(text).should == %Q|
          = link_to_function '<img alt="" id="1112590en_img" src="/images/down-arrow.png">', "$('#1112590en').toggle();imgswap('1112590en_img')"
          %span.ClauseTitle_text<
            = link_to_function "Reports on implementation of Law Commission proposals", "$('#1112590en').toggle();imgswap('1112590en_img')"
      #1112590en.ClauseTextWithExplanatoryNote
|
    end

    it 'should not have a toggle link around act clause title' do
      text = %Q|            #1112875.ClauseTitle
              %p#1112877._ClauseTitle_PgfTag
                %span.PgfNumString
                  %span.PgfNumString_1
                    “21A
                %a{ :name => "page2-line3" }
                %a{ :name => "clause4-page2-line3" }
                %span.ActClauseTitle_text
                  Fees
            #1112440.ClauseText
|
      @utils.format_haml(text).should == %Q|            #1112875.ClauseTitle
              %p#1112877._ClauseTitle_PgfTag
                %span.PgfNumString<
                  %span.PgfNumString_1<>
                    “21A
                %a{ :name => "page2-line3" }<>
                %a{ :name => "clause4-page2-line3" }<>
                %span.ActClauseTitle_text<
                  Fees
            #1112440.ClauseText
|
    end

    it 'should expand line number span' do
      text = %Q|%span#1043312.Line
                line
                %span.Line_number
                  42
              %span#1043322.Number
|
      @utils.format_haml(text).should == %Q|%span#1043312.Line<
                line <span class="Line_number">42</span>
              %span#1043322.Number<
|
    end

    it 'should expand xref span 2' do
      text = %Q|                %span.SubSection_text
                  In consequence of subsection
                  %span#1123927.Xref
                    (6)
                  ) omit—
              #1113761.Para
|
      @utils.format_haml(text).should == %Q|                %span.SubSection_text<
                  In consequence of subsection <span class="Xref" id="1123927">(6)</span>) omit—
              #1113761.Para
|
    end

    it 'should expand xref span 1' do
      text = %Q|
                  In subsection
                  %span#4312126.Xref
                    (10)
                  , and
                  %span|
      @utils.format_haml(text).should == %Q|
                  In subsection <span class="Xref" id="4312126">(10)</span>, and
                  %span|
    end

    it 'should expand xref span' do
      text = %Q|
                  In subsection
                  %span#4312126.Xref
                    (10)
                  ,|
      @utils.format_haml(text).should == %Q|
                  In subsection <span class="Xref" id="4312126">(10)</span>,|
    end

    it 'should expand xref anchor if followed by comma' do
      html = %Q|to <a id="1131516" class="Xref" href="#clause2-1-amendment-clause134A-5">(5)</a>, a change is significant if OFCOM|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|to&nbsp;
%a#1131516.Xref{ :href => "#clause2-1-amendment-clause134A-5" }><
  (5)
, a change is significant if OFCOM
|
    end

    it 'should expand xref anchor if followed by ")"' do
      html = %Q|
      <a id="1131516" class="Xref" href="#clause2-1-amendment-clause134A-5">(5)</a>). a change is significant if OFCOM|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|\\&nbsp;
%a#1131516.Xref{ :href => "#clause2-1-amendment-clause134A-5" }><
  (5)
). a change is significant if OFCOM
|
    end

    it 'should expand three anchors in a row' do
      html = 'in <a id="1125123" class="Citation" href="#clause9-amendment-clause124F-4-a">(4)(a)</a>,  <a id="1125134" class="Xref" href="#clause9-amendment-clause124F-4-e">(e)</a> and'
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|in&nbsp;
%a#1125123.Citation{ :href => "#clause9-amendment-clause124F-4-a" }><
  (4)(a)
,
%a#1125134.Xref{ :href => "#clause9-amendment-clause124F-4-e" }<
  (e)
and\n|
    end

    it 'should expand xref followed by ;' do
      html = %Q|and <a id="1125146" class="Xref" href="#clause9-amendment-clause124F-4-f">(f)</a>; and|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|and&nbsp;
%a#1125146.Xref{ :href => "#clause9-amendment-clause124F-4-f" }><
  (f)
; and
|
    end

    it 'should expand clause number span' do
      text = %Q|
            %span#1485163.Number
              Clause
              %span.Clause_number
                1
              ,|
      @utils.format_haml(text).should == %Q|
            %span#1485163.Number<
              Clause <span class="Clause_number">1</span>,|
    end

    def generate_haml html
      html = @utils.preprocess(html)
      html_file = Tempfile.new("#{Time.now.to_i.to_s}.html", "#{RAILS_ROOT}/tmp")
      html_file.write html
      html_file.close
      cmd = "html2haml #{html_file.path}"
      haml = `#{cmd}`
      html_file.delete
      haml
    end
    
    it 'should expand anchor followed by comma' do
      html = 'in <a href="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb5-l1g17" title="subsection (2)" rel="cite" resource="http://www.legislation.gov.uk/ukpga/1996/61/section/17/2">subsection (2)</a>, the words'
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|in&nbsp;
%a{ :href => "http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb5-l1g17", :title => "subsection (2)", :rel => "cite", :resource => "http://www.legislation.gov.uk/ukpga/1996/61/section/17/2" }><
  subsection (2)
, the words\n|
    end

    it 'should expand citation anchor followed by comma' do
      html = %Q|
      <a id="1116344" class="Citation" href="http://www.statutelaw.gov.uk/documents/1979/2/ukpga/c2" title="Customs and Excise Management Act 1979 (c. 2)">Customs and Excise Management Act 1979 (c. 2)</a>, etc|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|\\&nbsp;
%a#1116344.Citation{ :href => "http://www.statutelaw.gov.uk/documents/1979/2/ukpga/c2", :title => "Customs and Excise Management Act 1979 (c. 2)" }><
  Customs and Excise Management Act 1979 (c. 2)
, etc
|
    end

    it 'should expand anchor followed by a semicolon' do
      html = %Q|
      <a name="page67-line7"></a><a name="clause106-page67-line7"></a>;
|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|\\&nbsp;
%a{ :name => "page67-line7" }><
%a{ :name => "clause106-page67-line7" }<>
;
|
    end

    it 'should expand citation span followed by comma' do
      html = %Q|
      <span class="Citation">Capital Transfer Tax Act 1984 (c. 51)</span>, |
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|\\&nbsp;
%span.Citation>
  Capital Transfer Tax Act 1984 (c. 51)
,
|
    end

    it 'should expand anchor followed by semicolon' do
      html = %Q|
      <a href="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb6-l1g21" title="subsections (2) to (5)" rel="cite" resource="http://www.legislation.gov.uk/ukpga/1996/61/section/21/2">subsections (2) to (5)</a>;
|
      haml = generate_haml(html)
      @utils.format_haml(haml).should == %Q|\\&nbsp;
%a{ :href => "http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb6-l1g21", :title => "subsections (2) to (5)", :rel => "cite", :resource => "http://www.legislation.gov.uk/ukpga/1996/61/section/21/2" }><
  subsections (2) to (5)
;
|
    end

    it 'should expand clause number with square brackets span' do
      text = %Q|
            %span#1485163.Number
              [Clause
              %span.Clause_number
                1
              ],|
      @utils.format_haml(text).should == %Q|
            %span#1485163.Number<
              [Clause <span class="Clause_number">1</span>],|
    end

    it 'should line break if anchor outside div' do
      text = %Q|        %a{ :name => "page27-line3" }<>
        #1045605.CommitteeShorttitle<|
      @utils.format_haml(text).should == text.sub('<>','')
    end

    it 'should convert \&nbsp; to \ ' do
      @utils.format_haml('\&nbsp; ').should == '\ '
    end

    it 'should convert \. to %span<>\n \.' do
      @utils.format_haml("              \\.\n").should == "              %span<>                \\.\n"
    end
  end
end