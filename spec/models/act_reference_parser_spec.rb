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
        :opsi_url => 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1')
      act.stub!(:find_section_by_number).and_return mock_model(ActSection,
        :legislation_url=> 'http://www.legislation.gov.uk/ukpga/1996/61/section/56',
        :statutelaw_url => 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56',
        :title => 'Interpretation')
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

    it 'should put rel cite anchor element around reference to section of act' do
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('a[rel="cite"]', :text => 'section 56 of the 1996 Act')
      end
    end

    it 'should put rel cite anchor element with resource around reference to section of act' do
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61/section/56"]', :text => 'section 56 of the 1996 Act')
      end
    end

    it 'should put rel cite anchor element with href around reference to section of act' do
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('a[href="http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/56"]', :text => 'section 56 of the 1996 Act')
      end
    end

    it 'should put rel cite anchor element with title around reference to section of act' do
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('a[title="Interpretation"]', :text => 'section 56 of the 1996 Act')
      end
    end
  end

end