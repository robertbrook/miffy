require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe ActReferenceParser do

  describe 'when parsing XML file' do
    before(:all) do
      @parser = ActReferenceParser.new
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
        with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61/56"]')
        with_tag('a[href="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1"]')
      end
    end
  end

end