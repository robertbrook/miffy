require 'mifparserutils'

class MifTableParser

  include MifParserUtils

  def get_tables doc
    @format_info = {}
    table_formats = (doc/'TblCatalog/TblFormat')
    table_formats.each do |format|
      handle_format format
    end
    
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
    if node.at('TblXColumnRuling/text()')
      col_x_border = clean(node.at('TblXColumnRuling/text()'))
    end
    
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
        "col_x_border" => "#{col_x_border}"
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
      css_class = get_table_css_class(node)
      
      xml_tag = start_tag('TableData', node)
            
      unless css_class.empty?
        if xml_tag.include?('class=')
          xml_tag.gsub!('">', %Q| #{css_class}">|)
        else
          xml_tag.gsub!('>', %Q| class="#{css_class}">|)
        end
      end
      
      tables[@current_table_id] = [xml_tag]
      
      do_break = false
    end
    do_break
  end

  def handle_row node, tables
    @cell_count = 0
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
        @cell_count += 1
        return
      else
        @colspan_target = 0
      end
    end
    
    colspan = 1
    if node.at('CellColumns/text()')
      colspan = node.at('CellColumns/text()').to_s
      colspan = colspan.to_i
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
    
    css_class = ""
    unless @format_info[@table_tag]["col_x_border"].empty?
      if (@format_info[@table_tag]["col_x"] == @cell_count.to_s && !@in_heading) ||
        (@format_info[@table_tag]["col_x"].to_i == @cell_count.to_i + (colspan-1) && !@in_heading)
        if first == ""
          css_class = %Q| class="leftborder"|
          if @no_of_cols.to_i+-1 != @cell_count.to_i+(colspan-1)
            css_class = %Q| class="leftborder rightborder"|
          end
        else
          if @no_of_cols.to_i-1 != @cell_count+(colspan-1)
            css_class = %Q| class="rightborder"|
          end
        end
      end
    end
    
    unless @format_info[@table_tag]["col_border"].empty?
      if first != ""
        css_class = ' class="rightborder"'
      elsif @cell_count+colspan == @no_of_cols.to_i-1
        css_class = ' class="leftborder"'
      else
        if @no_of_cols.to_i-1 != @cell_count+(colspan-1)
          css_class = %Q| class="rightborder"|
        end
      end
    end
    
    #assumes that if a Ruling node is used in this position then it is set to a valid value
    if node.at('CellTRuling/text()') && node.at('CellRRuling/text()') && node.at('CellBRuling/text()') && node.at('CellLRuling/text()')
      css_class = %Q| class="allborders"|
    else
      if node.at('CellTRuling/text()')
        css_class.gsub!('class="', 'class="topborder ') unless css_class.include?('topborder')
      end
      if node.at('CellRRuling/text()')
        css_class.gsub!('class="', 'class="rightborder ') unless css_class.include?('rightborder')
      end
      if node.at('CellBRuling/text()')
        css_class.gsub!('class="', 'class="bottomborder ') unless css_class.include?('bottomborder')
      end
      if node.at('CellLRuling/text()')
        css_class.gsub!('class="', 'class="leftborder ') unless css_class.include?('leftborder')
      end
    end      
    
    if first != "" && css_class != ""
      first = ""
      css_class.gsub!('class="', 'class="first ')
    end
    if @in_heading
      tables[@current_table_id] << %Q|<CellH id="#{cell_id}"#{first}#{css_class}>|
    else
      tables[@current_table_id] << %Q|<Cell id="#{cell_id}"#{first}#{css_class}>|
    end
    @cell_count += 1
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
  
  def get_table_css_class node
    css_class = ""
    if !@format_info[@table_tag]["border_top"].empty? && !@format_info[@table_tag]["border_right"].empty? && !@format_info[@table_tag]["border_bottom"].empty? && !@format_info[@table_tag]["border_left"].empty?
      css_class = "allborders"
    else
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
      
      if node.parent.at('TblFormat/TblTRuling/text()') && node.parent.at('TblFormat/TblLRuling/text()') && node.parent.at('TblFormat/TblBRuling/text()') && node.parent.at('TblFormat/TblRRuling/text()')
        css_class = "allborders"
      else
        if node.parent.at('TblFormat/TblTRuling/text()')
          css_class += " topborder" unless css_class.include?("topborder")
        end
        if node.parent.at('TblFormat/TblRRuling/text()')
          css_class += " rightborder" unless css_class.include?("rightborder")
        end
        if node.parent.at('TblFormat/TblBRuling/text()')
          css_class += " bottomborder" unless css_class.include?("bottomborder")
        end
        if node.parent.at('TblFormat/TblLRuling/text()')
          css_class += " leftborder" unless css_class.include?("leftborder")
        end
      end
    end
    
    css_class.strip
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
    @no_of_cols = table_xml.at('TblNumColumns/text()').to_s

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