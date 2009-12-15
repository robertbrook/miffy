require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifTableParser do
  
  describe 'when parsing a table with no formatting information' do
    it 'should create table' do
      doc = Hpricot.XML fixture('table_examples/table.xml')
      tables = MifTableParser.new.get_tables doc
      tables["21"].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first" colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886" colspan="2">Rate</CellH>
</Row>
<Row id="1146888">
<CellH id="1146889" class="first">(1)</CellH>
<CellH id="1146890">(2)</CellH>
<CellH id="1146891">(3)</CellH>
<CellH id="1146892">(4)</CellH>
</Row>
<Row id="1146903">
<Cell id="1146904" class="first">100</Cell>
<Cell id="1146905" class="centered">120</Cell>
<Cell id="1146906">15</Cell>
<Cell id="1146907">35</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
  end
  
  describe 'when parsing a table with TblXColumnRuling set in the TblCatalog section' do
    before(:all) do
      doc = Hpricot.XML fixture('table_examples/table_x_col_ruling.xml')
      @tables = MifTableParser.new.get_tables doc
    end
    
    it 'should add left and right borders to a matching column that is not at the edge of a table' do
      @tables["21"].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first" colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886">Rate</CellH>
</Row>
<Row id="1146888">
<CellH id="1146889" class="first">(1)</CellH>
<CellH id="1146890">(2)</CellH>
<CellH id="1146891">(3)</CellH>
</Row>
<Row id="1146903">
<Cell id="1146904" class="first">100</Cell>
<Cell id="1146905" class="leftborder rightborder centered">120</Cell>
<Cell id="1146906">15</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
    
    it 'should only add a left border to a matching column that is the last in the row' do      
      @tables["22"].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first" colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886">Rate</CellH>
</Row>
<Row id="1146888">
<Cell id="1146889" class="first">(1)</Cell>
<Cell id="1146890" class="leftborder" colspan="2">(3)</Cell>
</Row>
<Row id="1146903">
<Cell id="1146904" class="first">100</Cell>
<Cell id="1146905" class="centered">120</Cell>
<Cell id="1146906" class="leftborder">15</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
    
    it 'should only add a right border to a matching column that is the first in the row' do
      @tables["23"].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first" colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886">Rate</CellH>
</Row>
<Row id="1146888">
<Cell id="1146889" class="first rightborder">(1)</Cell>
<Cell id="1146890" colspan="2">(3)</Cell>
</Row>
<Row id="1146903">
<Cell id="1146904" class="first rightborder">100</Cell>
<Cell id="1146905" class="centered">120</Cell>
<Cell id="1146906">15</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
  end
  
  describe 'when parsing a table with TblColumnRuling set in the TblCatalog section' do
    it 'should create table with internal borders' do
      doc = Hpricot.XML fixture('table_examples/table_col_ruling.xml')
      tables = MifTableParser.new.get_tables doc
      tables["22"].to_s.should == '<TableData id="1147573">
<Row id="1146883">
<CellH id="1146884" class="first rightborder" colspan="2">CO2 emissions figure</CellH>
<CellH id="1146886" class="leftborder">Rate</CellH>
</Row>
<Row id="1146888">
<Cell id="1146889" class="first rightborder">(1)</Cell>
<Cell id="1146890" class="leftborder" colspan="2">(3)</Cell>
</Row>
<Row id="1146903">
<Cell id="1146904" class="first rightborder">100</Cell>
<Cell id="1146905" class="leftborder rightborder centered">120</Cell>
<Cell id="1146906" class="leftborder">15</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
  end
  
  describe 'when parsing complex tables with Ruling set in TblCatalog and locally' do
    before(:all) do
      doc = Hpricot.XML fixture('table_examples/complex_tables.xml')
      @tables = MifTableParser.new.get_tables doc
    end
    
    it 'should create table' do
      @tables["19"].to_s.should == '<TableData id="1115874">
<Row id="1115875" class="bottomborder">
<CellH id="1115878" class="first bottomborder topborder rightborder">Description of wine or made-wine</CellH>
<CellH id="1114648" class="allborders">Rates of duty per litre of alcohol in the wine or made-wine</CellH>
</Row>
<Row id="1115673">
<Cell id="1115678" class="first allborders">Wine or made-wine of a strength exceeding 22 per cent</Cell>
<Cell id="1115679" class="allborders">21.35.</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
    
    it 'should create a border around the table where Ruling set locally' do
      @tables["24"].to_s.should == '<TableData id="1172510" class="allborders">
<Row id="1162636" class="bottomborder">
<CellH id="1162639" class="first rightborder">Months for which licence granted</CellH>
<CellH id="1162642" class="leftborder rightborder">Category A</CellH>
<CellH id="1162645" class="leftborder rightborder">Category B1</CellH>
<CellH id="1162648" class="leftborder rightborder">Category B2</CellH>
<CellH id="1162651" class="leftborder rightborder">Category B3</CellH>
<CellH id="1162654" class="leftborder rightborder">Category B4</CellH>
<CellH id="1162657" class="leftborder">Category C</CellH>
</Row>
<Row id="1162658">
<Cell id="1162661" class="first allborders">1</Cell>
<Cell id="1162664" class="allborders">455</Cell>
<Cell id="1162667" class="allborders">230</Cell>
<Cell id="1162670" class="allborders">180</Cell>
<Cell id="1162673" class="allborders">180</Cell>
<Cell id="1162676" class="allborders"> 165</Cell>
<Cell id="1162679" class="leftborder">70</Cell>
</Row>
</TableData>'.gsub("\n",'')
    end
  end
end