require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'rexml/document'

module MifParserUtils

  def clean element
    element.at('text()').to_s[/`(.+)'/]
    text = $1
    if text
      text.gsub!('\xd4 ', '‘')
      text.gsub!('\xd5 ','’')
      text.gsub!('\xd2 ','“')
      text.gsub!('\xd3 ','”')
    else
      ''
    end
    text
  end

  def get_char element
    char = element.at('text()').to_s
    case char
      when 'EmSpace'
        ' '
      when 'Pound'
        '£'
      when 'EmDash'
        '—'
      when 'HardReturn'
        "/n"
      else
        '[[' + char + ']]'
    end
  end
end

class MifParser

  VERSION = "0.0.0"

  include MifParserUtils

  # e.g. parser.parse("pbc0930106a.mif")
  def parse mif_file, options={}
    xml_file = Tempfile.new("#{mif_file.gsub('/','_')}.xml", "#{RAILS_ROOT}/tmp")
    xml_file.close # was open
    Kernel.system "mif2xml < #{mif_file} > #{xml_file.path}"
    result = parse_xml_file(xml_file.path, options)
    xml_file.delete
    result
  end

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    parse_xml(IO.read(xml_file), options)
  end

  def is_instructions?(flow)
    instruction_regexp = /(`Header'|StructMasterPageMaps|REISSUE|Running H\/F|line of text which is to be numbered|Use the following fragment to insert an amendment line number)/
    flow.inner_text[instruction_regexp] ||
    (flow.at('PgfTag') && flow.at('PgfTag/text()').to_s[/(AmendmentLineNumber|\.PageNum|Body|\.A|\.Bill|\.To)/])
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    xml = ['<Document>']

    @table_list = {}
    tables = (doc/'Tbls/Tbl')
    tables.each do |table|
      handle_table(table, @table_list)
    end
    
    @frame_list = {}
    frames = (doc/'AFrames'/'Frame')
    frames.each do |frame|
      handle_frame(frame, @frame_list)
    end
    
    @variable_list = {}
    variables = (doc/'VariableFormats'/'VariableFormat')
    variables.each do |variable|
      handle_variable(variable, @variable_list)
    end

    flows = (doc/'TextFlow')
    flows.each do |flow|
      unless is_instructions?(flow)
        handle_flow(flow, xml)
      end
    end

    xml << ['</Document>']
    xml = xml.join('')
    begin
      doc = REXML::Document.new(xml)
    rescue Exception => e
      puts e.to_s
      raise e
    end

    if options[:indent]
      indented = ''
      doc.write(indented,2)
      indented
    else
      xml
    end
  end
  
  def handle_variable var_xml, vars
    @var_id = ''
    
    var_xml.traverse_element do |element|
      case element.name
        when 'VariableName'
          @var_id = clean(element.at('text()'))
        when 'VariableDef'
          var_value = clean(element.at('text()'))
          vars.merge!({"#{@var_id}", "#{var_value}"})
      end
    end
  end
  
  def handle_frame frame_xml, frames
    @frame_id = ''
    @in_frame = false
    @e_tag = ''
    
    frame_xml.traverse_element do |element|
      case element.name
        when 'ID'
          @frame_id = element.at('text()').to_s
        when 'Unique'
          unless @frame_id == '' or @in_frame
            unique_id = element.at('text()').to_s
            frames.merge!({@frame_id, %Q|<FrameData id="#{unique_id}">|})
            @in_frame = true
          end
        when 'ETag'
          tag = clean(element)
          @e_tag = tag
          uid = element.at('../Unique/text()').to_s
          attributes = get_attributes(element)
          frames[@frame_id] << %Q|<#{tag} id="#{uid}"#{attributes}>|
        when 'String'
          text = clean(element.at('text()'))
          frames[@frame_id] << text
      end
    end
    
    if frames[@frame_id] 
      unless @e_tag.empty?
        frames[@frame_id] << "</#{@e_tag}>"
      end
      frames[@frame_id] << "</FrameData>"
    end
  end

  def handle_table table_xml, tables
    hash_size = tables.size
    @current_table_id = nil
    @in_row = false
    @in_cell= false
    @in_heading = false

    table_xml.traverse_element do |element|
      case element.name
        when 'TblID'
          @current_table_id = element.at('text()').to_s
        when 'TblTag'
          tag = clean(element.at('text()'))
          if tag != 'Table'
            break
          else
            table_id = element.at('../Unique/text()').to_s
            tables.merge!({@current_table_id, %Q|<TableData id="#{table_id}">|})
          end
        when 'Row'
          if @in_row
            tables[@current_table_id] << "</Cell></Row>"
            @in_row = false
            @in_cell = false
          end
          row_id = element.at('Element/Unique/text()').to_s
          @in_row = true
          tables[@current_table_id] << %Q|<Row id="#{row_id}">|
        when 'Cell'
          first = ' class="first" '
          if @in_cell
            first = ""
            if @in_heading
              tables[@current_table_id] << "</CellH>"
            else
              tables[@current_table_id] << "</Cell>"
            end
          end
          cell_id = element.at('Element/Unique/text()').to_s
          @in_cell = true
          if @in_heading
            tables[@current_table_id] << %Q|<CellH id="#{cell_id}"#{first}>|
          else
            tables[@current_table_id] << %Q|<Cell id="#{cell_id}"#{first}>|
          end
        when 'TblH'
          @in_heading = true
        when 'TblBody'
          tables[@current_table_id] << '</CellH></Row>'
          @in_row = false
          @in_cell = false
          @in_heading = false
        when 'String'
          text = clean(element.at('text()'))
          tables[@current_table_id] << text
        when 'Char'
          text = get_char(element)
          tables[@current_table_id] << text
      end
    end

    if tables.size > hash_size
      tables[@current_table_id] << "</Cell></Row></TableData>"
    end
  end

  def handle_pgf_tag element
    flush_strings
    tag = clean(element).gsub(' ','_')
    @pgf_tag = "#{tag}_PgfTag"
    @pgf_tag_id = element.at('../Unique/text()').to_s

    if tag == 'AmendmentNumber' || tag == 'AmedTextCommitReport'
      add_pgf_tag
    end
    @last_was_pdf_num_string = false
  end

  def add_pgf_tag
    if @pgf_tag
      if @pgf_tag_id
        add %Q|\n<#{@pgf_tag} id="#{@pgf_tag_id}">|
        @pgf_tag_id = nil
      else
        add "\n<#{@pgf_tag}>"
      end
      @in_paragraph = true
    end
  end

  def get_attributes element
    attributes = (element/'../Attributes/Attribute')
    attribute_list = ''
    if attributes && attributes.size > 0
      attributes.each do |attribute|
        name = clean(attribute.at('AttrName/text()'))
        value = clean(attribute.at('AttrValue/text()'))
        attribute_list += %Q| #{name}="#{value}"|
      end
    end
    attribute_list
  end

  def move_etag_outside_paragraph?(element, tag)
    collapsed = element.at('../Collapsed/text()').to_s == 'Yes'
    @in_paragraph && (collapsed ||
            tag == 'Committee' ||
            tag == 'Resolution' ||
            tag == 'Amendment' ||
            tag == 'Amendment.Number' ||
            tag == 'Amendment.Text' ||
            tag == 'SubSection' ||
            tag == 'Clauses.ar' ||
            tag == 'Clause.ar' ||
            tag == 'ClauseText' ||
            tag == 'ResolutionHead' ||
            tag == 'ResolutionText' ||
            tag == 'OrderDate' ||
            tag == 'OrderHeading' ||
            tag == 'ClauseTitle' ||
            tag == 'Clause' ||
            tag == 'Para.sch' )
  end

  def move_etag_outside_paragraph tag, uid, attributes
    line = @xml.pop
    lines = []
    while !line.include?(@pgf_tag)
      if line[/PgfNumString/]
        pgf_num_string = line
      else
        lines << line
      end
      line = @xml.pop
    end
    pgf_start_tag = line

    add %Q|<#{tag} id="#{uid}"#{attributes}>|
    add pgf_start_tag
    add pgf_num_string if pgf_num_string
    lines.reverse.each {|line| add line}
    @opened_in_paragraph.clear
  end

  def handle_etag element
    flush_strings
    tag = clean(element)
    @etags_stack << tag
    @e_tag = tag
    uid = element.at('../Unique/text()').to_s
    attributes = get_attributes(element)

    if move_etag_outside_paragraph?(element, tag)
      move_etag_outside_paragraph tag, uid, attributes
    else
      add %Q|<#{tag} id="#{uid}"#{attributes}>|
      @opened_in_paragraph[tag] = true if @in_paragraph
    end
  end

  def handle_para
    flush_strings
    if @in_paragraph
      if @opened_in_paragraph.size > 1
        raise "can not handle all elements opened in <#{@pgf_tag}> paragraph: #{@opened_in_paragraph.keys.inspect}"
      elsif @opened_in_paragraph.size == 1
        last_line = @xml.pop
        if last_line.include?(@opened_in_paragraph.keys.first)
          add "</#{@pgf_tag}>\n"
          add last_line
          @pgf_tag = nil
          @in_paragraph = false
          @opened_in_paragraph.clear
        else
          raise "too tricky to close <#{@pgf_tag}> paragraph, opened element: #{@opened_in_paragraph.keys.first} last_line: #{last_line} xml: #{@xml.join("\n").reverse[0..1000].reverse}"
        end
      else
        add "</#{@pgf_tag}>\n"
        @pgf_tag = nil
        @in_paragraph = false
        @opened_in_paragraph.clear
      end
    end
  end

  def handle_element_end element
    flush_strings
    tag = @etags_stack.pop
    
    if @in_paragraph && !@opened_in_paragraph[tag]
      # need to close paragraph
      add "</#{@pgf_tag}>\n"
      @pgf_tag = nil
      @in_paragraph = false
      @opened_in_paragraph.clear
    end
    @opened_in_paragraph.delete(tag)
    add "</#{tag}>"
    add "\n" unless tag[/(Day|STHouse|STLords|STText|ClauseTitle|Para|OrderPreamble)/]
  end

  def add text
    if text.nil?
      raise 'text should not be null'
    else
      @xml << text
    end
  end

  def handle_pgf_num_string element
    add_pgf_tag unless @in_paragraph
    string = clean(element)
    if string
      parts = ''
      string.split('\t').each_with_index do |part, i|
        parts += "<PgfNumString_#{i}>#{part}</PgfNumString_#{i}> " unless i == 0 && part.blank?
      end
      string = parts
    end
    add "<PgfNumString>#{string}</PgfNumString>"
    @last_was_pdf_num_string = true
  end

  def handle_string element
    text = clean(element)
    last_line = @strings.pop || ''

    if @prefix_end && text[/^\d+$/] && @e_tag
      last_line[/(Clause|Schedule)/]
      type = $1
      if type
        text = %Q|<#{type}_number>#{text}</#{type}_number>|
      else
        text = %Q|<#{@e_tag}_number>#{text}</#{@e_tag}_number>|
      end
    end

    last_line += text
    @strings << last_line 
  end
  
  def handle_char element
    last_line = @strings.pop || ''
    last_line += get_char(element)
    @strings << last_line
  end
  
  def flush_strings
    if @strings.size > 0
      if @strings.size == 1
        last_line = @xml.pop
        text = @strings.pop
        text_tag = @etags_stack.last
        
        if @last_was_pdf_num_string
          last_line += "<#{text_tag}_text>#{text}</#{text_tag}_text>"
        elsif text_tag == "ResolutionText"
          last_line += "<#{text_tag}_text>#{text}</#{text_tag}_text>"
        else
          last_line += text
        end
        add last_line
      else
        raise 'why is strings size > 1? ' + @strings.inspect
      end
    end
  end

  def handle_flow flow, xml
    @xml = xml
    @pgf_tag = nil
    @e_tag = nil
    @in_paragraph = false
    @prefix_end = false
    @opened_in_paragraph = {}
    @etags_stack = []
    @strings = []

    flow.traverse_element do |element|
      case element.name
        when 'PgfTag'          
          handle_pgf_tag element
        when 'ETag'          
          handle_etag element
        when 'Char'
          handle_char element
        when 'Para'
          @prefix_end = false          
          handle_para
        # when 'ParaLine'
          # add "\n"
        when 'PgfNumString'
          handle_pgf_num_string element
        when 'String'
          handle_string element
        when 'ElementEnd'          
          handle_element_end element
        when 'PrefixEnd'
          @prefix_end = true
        when 'SuffixBegin'
          @prefix_end = false
        when 'ATbl'
          table_id = element.at('text()').to_s
          add @table_list[table_id]
        when 'AFrame'
          frame_id = element.at('text()').to_s
          add @frame_list[frame_id]
        when 'VariableName'
          var_id = clean(element.at('text()'))
          last_line = @strings.pop || ''
          last_line += @variable_list[var_id]
          @strings << last_line
      end
    end
  end

end