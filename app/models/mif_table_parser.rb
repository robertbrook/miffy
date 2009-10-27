require 'mifparserutils'
require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'rexml/document'

class MifTableParser

  include MifParserUtils

  def get_tables doc
    tables = (doc/'Tbls/Tbl')
    tables.inject({}) do |hash, table|
      handle_table(table, hash)
    end
  end

  def handle_id node
    @current_table_id = node.at('text()').to_s
  end

  def handle_tag node, tables
    tag = clean(node)
    if tag != 'Table' && tag != 'RepealContinue'
      do_break = true
    else
      tables.merge!({@current_table_id, start_tag('TableData', node)})
      do_break = false
    end
    do_break
  end

  def handle_row node, tables
    if @in_row
      if @in_heading
        tables[@current_table_id] << "</CellH></Row>"
      else
        tables[@current_table_id] << "</Cell></Row>"
      end
      @in_row = false
      @in_cell = false
    end
    row_id = node.at('Element/Unique/text()').to_s
    @in_row = true
    tables[@current_table_id] << %Q|<Row id="#{row_id}">|
  end

  def handle_cell node, tables
    first = ' class="first" '
    if @in_cell
      first = ""
      if @in_heading
        tables[@current_table_id] << "</CellH>"
      else
        tables[@current_table_id] << "</Cell>"
      end
    end
    cell_id = node.at('Element/Unique/text()').to_s
    @in_cell = true
    if @in_heading
      tables[@current_table_id] << %Q|<CellH id="#{cell_id}"#{first}>|
    else
      tables[@current_table_id] << %Q|<Cell id="#{cell_id}"#{first}>|
    end
  end

  def handle_body tables
    tables[@current_table_id] << '</CellH></Row>' if @in_heading
    @in_row = false
    @in_cell = false
    @in_heading = false
  end

  def add_text text, tables
    tables[@current_table_id] << text
  end

  def handle_node node, tables
    do_break = false

    case node.name
      when 'TblID'
        handle_id node
      when 'TblTag'
        do_break = handle_tag(node, tables)
      when 'Row'
        handle_row node, tables
      when 'Cell'
        handle_cell node, tables
      when 'TblH'
        @in_heading = true
      when 'TblBody'
        handle_body tables
      when 'String'
        add_text clean(node), tables
      when 'Char'
        add_text get_char(node), tables
    end

    do_break
  end

  def handle_table table_xml, tables
    @current_table_id = nil
    @in_heading = false
    @in_row = false
    @in_cell= false
    table_count = tables.size

    table_xml.traverse_element do |node|
      do_break = handle_node node, tables
      break if do_break
    end

    if tables.size > table_count
      if @in_heading
        add_text "</CellH></Row></TableData>", tables
      else
        add_text "</Cell></Row></TableData>", tables
      end
    end

    tables
  end

end