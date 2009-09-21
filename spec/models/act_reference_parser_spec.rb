require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe ActReferenceParser do

  describe 'when parsing XML file' do
    before(:all) do
      @parser = ActReferenceParser.new
      @result = @parser.parse_xml(fixture('ChannelTunnel/ChannelTunnelClauses.xml'))
    end

    it 'should put rel cite anchor element around abbrebrivated act name' do
      @result.should have_tag('ClauseText[id="1113674"]') do
        with_tag('a[rel="cite"]', :text => 'the 1996 Act')
        with_tag('a[resource="http://www.legislation.gov.uk/ukpga/1996/61"]')
        with_tag('a[href="http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1"]')
      end
    end
  end

end