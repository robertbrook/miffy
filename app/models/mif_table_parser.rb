require 'mifparserutils'

class MifTableParser

  include MifParserUtils

  def get_tables doc
    @format_info = {}
    table_formats = (doc/'TblCatalog/TblFormat')
    table_formats.each do |format|
      handle_format format
    end
    #puts "****"
    #puts @format_info.inspect
    #puts "****"
    
    tables = (doc/'Tbls/Tbl')
    tables.inject({}) do |hash, table|
      handle_table(table, hash)
    end
  end

  def handle_format node    
    current_tag = clean(node.at('TblTag/text()'))
    
    border_top    = clean(node.at('TblTRuling/text()'))
    border_left   = clean(node.at('TblLRuling/text()'))
    border_bottom = clean(node.at('TblBRuling/text()'))
    border_right  = clean(node.at('TblRRuling/text()'))
    
    hf_separator  = clean(node.at('TblHFRowRuling/text()'))
    col_border    = clean(node.at('TblColumnRuling/text()'))
    row_border    = clean(node.at('TblBodyRowRuling/text()'))
    
    col_x = node.at('TblXColumnNum/text()')
    col_x_border_left = clean(node.at('TblXColumnRuling/text()'))
    
    @format_info.merge!({
        "#{current_tag}" => {
          "border_top" => "#{border_top}", 
          "border_left" => "#{border_left}",
          "border_bottom" => "#{border_bottom}",
          "border_right" => "#{border_right}",
          "hf_separator" => "#{hf_separator}",
          "col_border" => "#{col_border}",
          "row_border" => "#{row_border}",
          "col_x" => "#{col_x}",
          "col_x_border_left" => "#{col_x_border_left}"
        }})
  end

  def handle_id node
    @current_table_id = node.at('text()').to_s
  end

  def handle_tag node, tables
    tag = clean(node)
    @table_tag = tag
    if tag != 'Table' && tag != 'RepealContinue' && tag != 'RepealsSchedules'
      do_break = true
    else
      css_class = ""
      unless @format_info[@table_tag]["border_top"].empty?
        css_class += " topborder "
      end
      unless @format_info[@table_tag]["border_right"].empty?
        css_class += " rightborder"
      end
      unless @format_info[@table_tag]["border_bottom"].empty?
        css_class += " bottomborder"
      end
      unless @format_info[@table_tag]["border_left"].empty?
        css_class += " leftborder"
      end
      
      xml_tag = start_tag('TableData', node)
      
      if xml_tag.include?('class=')
        xml_tag.gsub!('">', %Q| #{css_class}">|)
      else
        xml_tag.gsub!('>', %Q| class="#{css_class}">|)
      end
      
      tables[@current_table_id] = [xml_tag]
      
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
    
    css_class = ""
    if !@format_info[@table_tag]["hf_separator"].empty? && @in_heading
      css_class = %Q| class="bottomborder"|
    end
    tables[@current_table_id] << %Q|<Row id="#{row_id}"#{css_class}>|
  end

  def handle_cell node, tables
    if @colspan_target > 0
      if @colspan_count < @colspan_target
        @colspan_count += 1
        return
      else
        @colspan_target = 0
      end
    end
    
    first = ' class="first"'
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
  
  def handle_cell_columns node, tables
    colspan = node.at('text()').to_s
    cell = tables[@current_table_id].pop
    cell = cell.gsub(">", %Q| colspan="#{colspan}">|)
    tables[@current_table_id] << cell
    @colspan_target = colspan.to_i
    @colspan_count = 1
  end

  def handle_attribute node, tables
    if clean(node.at('AttrName')) == 'Align'
      attr_value = clean(node.at('AttrValue'))
      alignment = ''
      case attr_value
        when 'Center'
          alignment = 'centered'
        when 'Right'
          alignment = 'right'
      end
      cell_start = tables[@current_table_id].pop
      if cell_start.include?('class=')
        cell_start.gsub!('">', %Q| #{alignment}">|)
      else
        cell_start.gsub!('>', %Q| class="#{alignment}">|)
      end
      tables[@current_table_id] << cell_start
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
      when 'Attribute'
        handle_attribute node, tables
      when 'CellColumns'
        handle_cell_columns node, tables
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
    @colspan_count = 0
    @colspan_target = 0
    @table_tag = ""
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