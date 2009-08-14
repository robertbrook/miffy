require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe ActToHtmlParser do

  def parser url=nil
    parser = ActToHtmlParser.new
    parser
  end

  describe 'when parsing Law Commissions Act XML file to html' do
    before(:all) do
      @result = parser.parse_xml(fixture('Acts/LawCommissionsAct.xml'), :format => :html)
    end
    it 'should create html' do
      # File.open('/Users/x/apps/uk/ex.html','w') {|f| f.write @result }
      @result.should have_tag('html')
      @result.should have_tag('div[id="Legislation"]') do
        with_tag('div[class="PrimaryPrelims"]') do
          with_tag('h1[class="Title"]', :text => 'Law Commissions Act 1965')
          with_tag('div[class="Number"]', :text => '1965 Chapter 22')
          with_tag('div[class="LongTitle"]', :text => 'An Act to provide for the constitution of Commissions for the reform of the law.')
        end
      end
    end
    
    it 'should handle clause titles correctly' do
      @result.should have_tag('div[class="P1"][id="section-1"]') do
        with_tag('div[class="P1Title"]') do
          with_tag('div[class="TitleNum"]', :text => '1')
          with_tag('div[class="Title"]', :text => 'The Law Commission')
        end
      end
    end
    
    it 'should handle nested clauses correctly' do
      @result.should have_tag('div[class="P2"][id="section-3-1"]') do
        with_tag('div[class="Pnumber"]', :text => '(1)')
        with_tag('div[class="P2para"]') do
          with_tag('div[class="Text"]', :text => 'It shall be the duty of each of the Commissions to take and keep under review all the law with which they are respectively concerned with a view to its systematic development and reform, including in particular the codification of such law, the elimination of anomalies, the repeal of obsolete and unnecessary enactments, the reduction of the number of separate enactments and generally the simplification and modernisation of the law, and for that purpose&#x2014;')
          with_tag('div[class="P3"][id="section-3-1-a"]') do
            with_tag('div[class="Pnumber"]', :text => '(a)')
            with_tag('div[class="P3para"]') do
              with_tag('div[class="Text"]' ,:text => 'to receive and consider any proposals for the reform of the law which may be made or referred to them;')
            end
          end
        end
      end
    end
  end
end