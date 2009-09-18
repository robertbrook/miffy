require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe ActReferenceParser do

  describe 'when parsing XML file' do
    before(:all) do
      @parser = ActReferenceParser.new
    end

    it 'should parse' do
      @result = @parser.parse_xml(fixture('ChannelTunnel/ChannelTunnelClauses.xml'))

      @result.should have_tag('ClauseText[id="1113674"]')
    end
  end

end