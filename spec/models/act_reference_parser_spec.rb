require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe ActReferenceParser do

  describe 'when finding internally referenced ids' do
    before(:all) do
      doc = Hpricot.XML fixture('DigitalEconomy/clauses_with_xref_ids.xml')
      @ids = ActReferenceParser.internal_ids(doc)
    end
    it 'should create hash of Ids' do
      @ids.size.should == 5
      @ids.should have_key("mf.451j-1112728")
      @ids.should have_key("mf.109j-1112598")
      @ids.should have_key("mf.102j-1118009")
      @ids.should have_key("mf.451j-1137360")
      @ids.should have_key("mf.451j-1136545")
    end

    it 'should create anchor for clause in amendment' do
      @ids["mf.451j-1112728"].should == 'clause4-amendment-clause124A'
      @ids["mf.109j-1112598"].should == 'clause42-amendment-clause116A'
    end
    it 'should create anchor for subsection of clause in amendment' do
      @ids["mf.451j-1137360"].should == 'clause4-amendment-clause124A-2'
    end
    it 'should create anchor for paragraph of subsection of clause in amendment' do
      @ids["mf.451j-1136545"].should == 'clause4-amendment-clause124A-5-g'
    end
    it 'should create anchor for subsection in amendment' do
      @ids["mf.102j-1118009"].should == 'clause38-6-amendment-subsection5A'
    end
  end

  describe 'when finding internally referenced ids in schedules' do
    before(:all) do
      doc = Hpricot.XML fixture('DigitalEconomy/schedules_with_xref_ids.xml')
      @ids = ActReferenceParser.internal_ids(doc)
    end
    it 'should create hash of Ids' do
      @ids.size.should == 4
      @ids.should have_key("mf.sA206j-1066552")
      @ids.should have_key("mf.sA206j-1066553")
      @ids.should have_key("mf.sA206j-1088963")
      @ids.should have_key("mf.s109j-1122371")
    end

    it 'should create anchor for Para.sch in schedule' do
      @ids["mf.sA206j-1066553"].should == 'schedule1-2'
      @ids["mf.sA206j-1088963"].should == 'schedule1-4'
    end

    it 'should create anchor for SubPara.sch in Para.sch' do
      @ids["mf.sA206j-1066552"].should == 'schedule1-2-1'
    end

    it 'should create anchor for Para.sch in amendment' do
      @ids["mf.s109j-1122371"].should == 'schedule2-1-amendment-scheduleA1-1'
    end
  end

  describe 'when finding internally referenced ids' do
    it 'should add anchor attributes' do
      doc = Hpricot.XML fixture('DigitalEconomy/clauses_with_xref_ids.xml')
      ActReferenceParser.handle_internal_ids(doc)
      xml = doc.to_s
      xml.should have_tag('Clause[anchor="clause4-amendment-clause124A"]')
      xml.should have_tag('Clause[anchor="clause42-amendment-clause116A"]')
      xml.should have_tag('SubSection[anchor="clause38-6-amendment-subsection5A"]')

      xml.should have_tag('Xref[id="1137592"][Idref="mf.451j-1112728"][anchor-ref="clause4-amendment-clause124A"]')
    end
  end

  describe 'when parsing act name split across two lines' do
    before(:all) do
      @parser = ActReferenceParser.new
      Act.stub!(:find_by_legislation_url).and_return nil
      Act.stub!(:find_by_name).and_return nil
      Act.stub!(:from_name).with('Video Recordings Act 1984').and_return mock(Act, :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61')

      @result = @parser.parse_xml(fixture('DigitalEconomy/clauses_act_name_on_two_lines.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/clauses_act_name_on_two_lines.act.xml','w') {|f| f.write @result }
    end

    it 'should not mark up part of act name' do
      @result.should include('<ParaLineStart LineNum="11"></ParaLineStart>Recordings Act 1984')
    end

    it 'should make full act name an anchor link' do
      @result.should include('<a href="http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61" rel="cite">Video <ParaLineStart LineNum="11"></ParaLineStart>Recordings Act 1984</a>')
    end
  end

  describe 'when parsing section of the act on same line' do
    before(:all) do
      @parser = ActReferenceParser.new
      Act.stub!(:find_by_legislation_url).and_return nil
      Act.stub!(:find_by_name).and_return nil

      @section_url = 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/3'

      section = mock(ActSection,
        :statutelaw_url => @section_url)
      act = mock(Act,
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61')
      act.stub!(:find_section_by_number).and_return section
      Act.stub!(:from_name).with('Communications Act 2003').and_return act

      @result = @parser.parse_xml(fixture('DigitalEconomy/clauses_section_of_the_act_same_line.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/clauses_section_of_the_act_same_line.act.xml','w') {|f| f.write @result }
    end

    it 'should not mark up part of act name' do
      @result.should have_tag('a[rel="cite"][href="' + @section_url + '"]', :text => 'Section 3 of the Communications Act 2003')
    end
  end

  describe 'when parsing ChannelTunnelClauses file' do
    before(:all) do
      @parser = ActReferenceParser.new
      act = mock_model(Act,
        :legislation_url=> 'http://www.legislation.gov.uk/ukpga/1996/61',
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61',
        :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1',
        :title => 'Channel Tunnel Rail Link Act 1996')
      act_section = mock_model(ActSection,
              :legislation_url => 'http://www.legislation.gov.uk/ukpga/1996/61/section/56',
              :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56',
              :title => 'Interpretation',
              :label => 'Section 56: Interpretation')
      act_section.stub!(:legislation_uri_for_subsection).and_return 'http://www.legislation.gov.uk/ukpga/1996/61/section/56/1'

      act.stub!(:find_section_by_number).and_return act_section
      Act.stub!(:find_by_legislation_url).and_return act

      other_act = mock_model(Act,
        :legislation_url=> 'http://www.legislation.gov.uk/ukpga/1996/61',
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61',
        :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1',
        :title => 'Railways Act 2005 (c. 14)')
      Act.stub!(:find_by_name).and_return other_act
      other_act.stub!(:find_section_by_number).and_return act_section

      @result = @parser.parse_xml(fixture('ChannelTunnel/ChannelTunnelClauses.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelClauses.act.xml','w') {|f| f.write @result }
    end

    # it 'should put rel cite anchor element around abbrebrivated act name' do
      # @result.should have_tag('ClauseText[id="1113674"]') do
        # with_tag('a[rel="cite"]', :text => 'the 1996 Act')
        # with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61"]')
        # with_tag('a[href="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1"]')
      # end
    # end

    describe 'when marking up reference to sections of act, ' do
      before(:all) do
        @sections = 'sections 31 to 33 of the 1996 Act'
      end

      it 'should put rel cite anchor element around reference' do
        @result.should have_tag('SubSection_PgfTag[id="1112746"]') do
          with_tag('a[rel="cite"]', :text => @sections)
        end
      end
    end

    describe 'when marking up reference to section of act, ' do

      describe 'and act is referenced by its full title' do
        before(:all) do
          @section = 'section 6 of the Railways Act 2005 (c. 14)'
        end

        it 'should put rel cite anchor element around reference' do
          @result.should have_tag('SubSection_PgfTag[id="1112746"]') do
            with_tag('a[rel="cite"]', :text => @section)
          end
        end
      end

      describe 'and act is referenced by an abbreviated name' do
        before(:all) do
          @section = 'section 56 of the 1996 Act'
        end

        it 'should put rel cite anchor element around reference' do
          @result.should have_tag('ClauseText[id="1113674"]') do
            with_tag('a[rel="cite"]', :text => @section)
          end
        end

        describe 'rel cite anchor' do
          it 'should have resource attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61/section/56"]', :text => @section)
            end
          end

          it 'should have href attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[href="http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56"]', :text => @section)
            end
          end

          it 'should have title attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[title="Section 56: Interpretation"]', :text => @section)
            end
          end
        end
      end
    end

    describe 'when marking up reference to subsections of act, ' do
      describe 'and reference is not in double quotes text' do
        before(:all) do
          @subsections = 'subsections (2) to (5)'
        end

        it 'should put rel cite anchor element around reference' do
          @result.should have_tag('Paragraph_PgfTag[id="1112835"]') do
            with_tag('a[rel="cite"]', :text => @subsections)
          end
        end
      end
    end

    describe 'when marking up reference to subsection of act, ' do

      describe 'and reference is in double quotes text' do
        before(:all) do
          @subsection = 'subsection (3)'
        end
        it 'should not put rel cite anchor element around reference' do
          prefix_text = '<Paragraph_PgfTag id="1112797"><PgfNumString><PgfNumString_1>(a)</PgfNumString_1> </PgfNumString><Para_text><ParaLineStart LineNum="16"></ParaLineStart>in <a href="http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56" title="subsection (2)" rel="cite" resource="http://www.legislation.gov.uk/ukpga/1996/61/section/56/1">subsection (2)</a>, the words '
          expected_text = '“Subject to subsection (3) below,”;'
          @result.should include(prefix_text + expected_text)
        end
      end

      describe 'and reference is not in double quotes text' do
        before(:all) do
          @subsection = 'subsection (1)'
        end

        it 'should put rel cite anchor element around reference' do
          @result.should have_tag('ClauseText[id="1113674"]') do
            with_tag('a[rel="cite"]', :text => @subsection)
          end
        end

        describe 'rel cite anchor' do
          it 'should have resource attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61/section/56/1"]', :text => @subsection)
            end
          end

          it 'should have href attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[href="http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56"]', :text => @section)
            end
          end

          it 'should have title attribute' do
            @result.should have_tag('ClauseText[id="1113674"]') do
              with_tag('a[title="subsection (1)"]', :text => @section)
            end
          end
        end
      end
    end
  end

  describe 'when parsing finance clauses file' do
    before(:all) do
      @parser = ActReferenceParser.new
      act = mock_model(Act,
        :legislation_url=> 'http://www.legislation.gov.uk/ukpga/1996/61',
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61',
        :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1',
        :title => 'Channel Tunnel Rail Link Act 1996')
      act_section = mock_model(ActSection,
              :legislation_url => 'http://www.legislation.gov.uk/ukpga/1996/61/section/56',
              :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56',
              :title => 'Interpretation',
              :label => 'Section 56: Interpretation')
      act_section.stub!(:legislation_uri_for_subsection).and_return 'http://www.legislation.gov.uk/ukpga/1996/61/section/56/1'

      act.stub!(:find_section_by_number).and_return act_section
      Act.stub!(:find_by_legislation_url).and_return act

      other_act = mock_model(Act,
        :legislation_url=> 'http://www.legislation.gov.uk/ukpga/1996/61',
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61',
        :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1',
        :title => 'Railways Act 2005 (c. 14)')
      Act.stub!(:find_by_name).and_return other_act
      other_act.stub!(:find_section_by_number).and_return act_section

      @result = @parser.parse_xml(fixture('finance/2R printed/Clauses_Interpretation_example.xml'))
      File.open(RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses_Interpretation_example.act.xml','w') {|f| f.write @result }
    end

    describe 'when parsing act with citation interpretation section' do
      it 'should make act abbreviation a link' do
        @result.should have_tag('a', :text => 'ALDA 1979')
      end
    end
    describe 'when parsing act without citation interpretation section' do
      it 'should make another act abbreviation a link' do
        @result.should have_tag('a', :text => 'CTTA 1984')
      end
    end

    describe 'when parsing act abbreviation without year' do
      it 'should make another act abbreviation a link' do
        @result.should have_tag('a', :text => 'ICTA')
      end
    end
  end

end