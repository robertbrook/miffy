require File.dirname(__FILE__) + '/../spec_helper.rb'

class MifParserUtilsExample
  include MifParserUtils
end

describe MifParserUtils do
  before :all do
    @utils = MifParserUtilsExample.new
  end

  describe 'when formatting certain spans' do
    def check span, ending
      @utils.format_haml("#{span}\n").should == "#{span}#{ending}\n"
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
      text = %Q|          %span.ClauseTitle_text<
            Reports on implementation of Law Commission proposals
      #1112590.ClauseText
|
      @utils.format_haml(text).should == %Q|          %span.ClauseTitle_text<
            = link_to_function "Reports on implementation of Law Commission proposals", "$('1112590').toggle()"
      #1112590.ClauseText
|
    end

    it 'should have toggle link around clause title when explanatory note present' do
      text = %Q|          %span.ClauseTitle_text<
            Reports on implementation of Law Commission proposals
      #1112590en.ClauseTextWithExplanatoryNote
|
      @utils.format_haml(text).should == %Q|          %span.ClauseTitle_text<
            = link_to_function "Reports on implementation of Law Commission proposals", "$('1112590en').toggle()"
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