require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe ActReferenceParser do

  describe 'when parsing XML file' do
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

end