require File.dirname(__FILE__) + '/../spec_helper.rb'

describe MifParser do

  before do
    @parser = MifParser.new
  end

  describe 'when creating new parser' do
    it 'should create parser' do
      @parser.should_not be_nil
    end
  end

  describe 'when parsing MIF file' do

    it 'should call out to mif2xml' do
      mif_file = 'pbc0930106a.mif'
      tempfile_path = '/var/folders/iZ/iZnGaCLQEnyh56cGeoHraU+++TI/-Tmp-/pbc0930106a.mif.xml.334.0'

      temp_xml_file = mock(Tempfile, :path => tempfile_path)
      Tempfile.should_receive(:new).with("#{mif_file}.xml", '.').and_return temp_xml_file
      temp_xml_file.should_receive(:close)
      Kernel.should_receive(:system).with("mif2xml < #{mif_file} > #{tempfile_path}")

      @parser.should_receive(:parse_xml_file).with(tempfile_path, {})
      temp_xml_file.should_receive(:delete)

      @parser.parse(mif_file)
    end

  end

  describe 'when parsing longer MIF XML file to html' do
    before do
      @result = @parser.parse_xml(fixture('pbc0900206m.mif.xml'))
    end
    it 'should make PgfTag into paragraphs' do
      # puts @result
    end
  end

  describe 'when parsing MIF XML file' do
    before do
      @result = @parser.parse_xml(fixture('pbc0930106a.mif.xml'))
    end

    it 'should remove instructions text' do
      @result.should_not include('Use the following fragment to insert an amendment line number')
      @result.should_not include('REISSUE')
      @result.should_not include('continued,')
      @result.should_not include('House of CommonsHouse of Commons')
    end

    it 'should make ETags into elements' do
      puts @result
      @result.should == "<Document><Amendments.Commons><Head><HeadNotice><NoticeOfAmds>Notices of Amendments</NoticeOfAmds>
<Given>given on</Given>
<Date><Day>Monday </Day><Date.text>1 June 2009</Date.text>
</Date>
<Stageheader>Public Bill Committee</Stageheader>
<CommitteeShorttitle><STText>Local Democracy, Economic Development and Construction Bill</STText><STHouse> [<STLords>Lords</STLords>]</STHouse></CommitteeShorttitle>
</HeadNotice>
</Head>
<PgfNumString>\\t</PgfNumString><Committee><NewClause.Committee><ClauseTitle>Award of construction projects</ClauseTitle>
<Sponsors><Sponsor>Ms Sally Keeble</Sponsor>
<Sponsor>Ms Dari Taylor</Sponsor>
<Sponsor>Joan Walley</Sponsor>
</Sponsors>
<Amendment.Number>NC1</Amendment.Number>
<Move>To move the following Clause:—</Move>
<ClauseText>‘In considering the award of a contract in accordance with the Housing Grant, Construction and Regeneration Act 1996 (c. 53), a local authority may have regard to—<PgfNumString>\\t(a)\\t</PgfNumString><Para>their functions under section 66 of the Local Democracy, Economic Development and Construction Act 2009 (local authority economic assessment); and</Para>
<PgfNumString>\\t(b)\\t</PgfNumString><Para>the desirability of maintaining a diverse range of contractors in its local authority area.’.</Para>
</ClauseText>
</NewClause.Committee>
 </Committee>
</Amendments.Commons>
</Document>"
      # @result.gsub('.','-').should have_tag('Amendments-Commons') do
        # with_tag('Head') do
          # with_tag('HeadNotice') do
            # with_tag('NoticeOfAmds', :text => 'Notices of Amendments')
            # with_tag('Given', :text => 'given on')
            # with_tag('Date', :text => 'Monday 1 June 2009') do
              # with_tag('Day', :text => 'Monday')
              # with_tag('Date-text', :text => '1 June 2009')
            # end
            # with_tag('Stageheader', :text => 'Public Bill Committee' )
            # with_tag('CommitteeShorttitle', :text => 'Local Democracy, Economic Development and Construction Bill [Lords]') do
              # with_tag('STText', :text => 'Local Democracy, Economic Development and Construction Bill')
              # with_tag('STHouse', :text => '[Lords]')
            # end
          # end
        # end
      # end
    end
  end

end