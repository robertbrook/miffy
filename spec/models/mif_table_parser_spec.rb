require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifTableParser do
  
  it 'should create table' do
    doc = Hpricot.XML TABLE
    tables = MifTableParser.new.get_tables doc
    tables.to_a.first[1].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first"  colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886" colspan="2">Rate</CellH>
</Row>
<Row id="1146888">
<CellH id="1146889" class="first" >(1)</CellH>
<CellH id="1146890">(2)</CellH>
<CellH id="1146891">(3)</CellH>
<CellH id="1146892">(4)</CellH>
</Row>
</TableData>'.gsub("\n",'')
  end

  TABLE = "
<Tbls><Tbl>
  <TblID>21</TblID>
  <TblTag>`Table'</TblTag>
  <TblNumColumns>4</TblNumColumns>
  <Unique>1147573</Unique>
  <TblColumnWidth>6.90551 pc</TblColumnWidth>
  <TblColumnWidth>6.84301 pc</TblColumnWidth>
  <TblColumnWidth>6.90551 pc</TblColumnWidth>
  <TblColumnWidth>6.90551 pc</TblColumnWidth>
  <Element>
    <Unique>1146880</Unique>
    <ETag>`Tgroup'</ETag>
    <Attributes></Attributes>
    <Collapsed>No</Collapsed>
    <SpecialCase>No</SpecialCase>
    <AttributeDisplay>None</AttributeDisplay>
  </Element>
  <TblH>
    <Element>
      <Unique>1146881</Unique>
      <ETag>`Thead'</ETag>
      <Attributes></Attributes>
      <Collapsed>No</Collapsed>
      <SpecialCase>No</SpecialCase>
      <AttributeDisplay>None</AttributeDisplay>
    </Element>
    <Row>
      <RowMaxHeight>84.0 pc</RowMaxHeight>
      <RowHeight>2.08333 pc</RowHeight>
      <Element>
        <Unique>1146883</Unique>
        <ETag>`Row'</ETag>
        <Attributes></Attributes>
        <Collapsed>Yes</Collapsed>
        <SpecialCase>No</SpecialCase>
        <AttributeDisplay>None</AttributeDisplay>
      </Element>
      <Cell>
        <CellColumns>2</CellColumns>
        <CellLRuling>`Thin'</CellLRuling>
        <CellBRuling>`Thin'</CellBRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146884</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147578</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <String>`CO'</String>
              <ElementBegin>
                <Unique>1147211</Unique>
                <ETag>`Sbscript'</ETag>
                <Attributes></Attributes>
                <Collapsed>No</Collapsed>
                <SpecialCase>No</SpecialCase>
                <AttributeDisplay>None</AttributeDisplay>
              </ElementBegin>
              <Font>
                <FTag>`Subscript'</FTag>
                <FLocked>No</FLocked>
              </Font>
              <String>`2'</String>
              <Font>
                <FTag>`'</FTag>
                <FLocked>No</FLocked>
              </Font>
              <ElementEnd>`Sbscript'</ElementEnd>
              <String>` emissions figure'</String>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellBRuling>`Thin'</CellBRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146885</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147580</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine></ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellColumns>2</CellColumns>
        <CellLRuling>`Thin'</CellLRuling>
        <CellBRuling>`Thin'</CellBRuling>
        <CellRRuling>`Thin'</CellRRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146886</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147582</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <String>`Rate'</String>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellBRuling>`Thin'</CellBRuling>
        <CellRRuling>`Thin'</CellRRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146887</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147584</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine></ParaLine>
          </Para>
        </CellContent>
      </Cell>
    </Row>
    <Row>
      <RowMaxHeight>84.0 pc</RowMaxHeight>
      <RowHeight>2.08333 pc</RowHeight>
      <Element>
        <Unique>1146888</Unique>
        <ETag>`Row'</ETag>
        <Attributes></Attributes>
        <Collapsed>Yes</Collapsed>
        <SpecialCase>No</SpecialCase>
        <AttributeDisplay>None</AttributeDisplay>
      </Element>
      <Cell>
        <CellLRuling>`Thin'</CellLRuling>
        <CellBRuling>`Thin'</CellBRuling>
        <Element>
          <Unique>1146889</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147589</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <ElementBegin>
                <Unique>1147230</Unique>
                <ETag>`Italic'</ETag>
                <Attributes></Attributes>
                <Collapsed>No</Collapsed>
                <SpecialCase>No</SpecialCase>
                <AttributeDisplay>None</AttributeDisplay>
              </ElementBegin>
              <String>`(1)'</String>
              <ElementEnd>`Italic'</ElementEnd>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellLRuling>`Thin'</CellLRuling>
        <CellRRuling>`Thin'</CellRRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146890</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147594</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <ElementBegin>
                <Unique>1147235</Unique>
                <ETag>`Italic'</ETag>
                <Attributes></Attributes>
                <Collapsed>No</Collapsed>
                <SpecialCase>No</SpecialCase>
                <AttributeDisplay>None</AttributeDisplay>
              </ElementBegin>
              <String>`(2)'</String>
              <ElementEnd>`Italic'</ElementEnd>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellLRuling>`Thin'</CellLRuling>
        <CellRRuling>`Thin'</CellRRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146891</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147599</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <ElementBegin>
                <Unique>1147240</Unique>
                <ETag>`Italic'</ETag>
                <Attributes></Attributes>
                <Collapsed>No</Collapsed>
                <SpecialCase>No</SpecialCase>
                <AttributeDisplay>None</AttributeDisplay>
              </ElementBegin>
              <String>`(3)'</String>
              <ElementEnd>`Italic'</ElementEnd>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
      <Cell>
        <CellLRuling>`Thin'</CellLRuling>
        <CellRRuling>`Thin'</CellRRuling>
        <CellTRuling>`Thin'</CellTRuling>
        <Element>
          <Unique>1146892</Unique>
          <ETag>`Entry'</ETag>
          <Attributes></Attributes>
          <Collapsed>No</Collapsed>
          <SpecialCase>No</SpecialCase>
          <AttributeDisplay>None</AttributeDisplay>
        </Element>
        <CellContent>
          <Notes></Notes>
          <Para>
            <Unique>1147604</Unique>
            <PgfTag>`CellHeading'</PgfTag>
            <ParaLine>
              <ElementBegin>
                <Unique>1147245</Unique>
                <ETag>`Italic'</ETag>
                <Attributes></Attributes>
                <Collapsed>No</Collapsed>
                <SpecialCase>No</SpecialCase>
                <AttributeDisplay>None</AttributeDisplay>
              </ElementBegin>
              <String>`(4)'</String>
              <ElementEnd>`Italic'</ElementEnd>
            </ParaLine>
          </Para>
        </CellContent>
      </Cell>
    </Row>
  </TblH>
</Tbl></Tbls>"
end