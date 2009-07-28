require 'mifparserutils'
require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'rexml/document'

class MifPage
  attr_accessor :unique_id, :page_type, :page_num
end

class AmendmentReference
  attr_accessor :number_type, :number, :page_number, :line_number
end

class MifParser

  include MifParserUtils

  # e.g. parser.parse("pbc0930106a.mif")
  def parse mif_file, options={}
    mif_xml_file = Tempfile.new("#{mif_file.gsub('/','_')}.xml", "#{RAILS_ROOT}/tmp")
    mif_xml_file.close # was open
    Kernel.system "mif2xml < #{mif_file} > #{mif_xml_file.path}"
    result = parse_xml_file(mif_xml_file.path, options)
    mif_xml_file.delete
    result
  end

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file mif_xml_file, options
    parse_xml(IO.read(mif_xml_file), options)
  end

  def is_instructions?(flow)
    instruction_regexp = /(`Header'|StructMasterPageMaps|REISSUE|Running H\/F|line of text which is to be numbered|Use the following fragment to insert an amendment line number)/
    flow.inner_text[instruction_regexp] ||
    (flow.at('PgfTag') && flow.at('PgfTag/text()').to_s[/(AmendmentLineNumber|\.PageNum|Body|\.A|\.Bill|\.To)/])
  end
  
  def parse_xml mif_xml, options={}
    doc = Hpricot.XML mif_xml
    xml = make_xml(doc)
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
  

  def initialize_doc_state doc
    @bill_attributes = get_bill_attributes doc    
    @table_list = get_tables doc
    @frame_list = get_frames doc
    @pages = get_pages doc
    @variable_list = get_variables doc    
  end

  def make_xml doc
    initialize_doc_state doc
    @xml = ['<Document><BillData>']
    add_bill_attribute 'ShortTitle', 'BillTitle'
    (doc/'TextFlow').each do |flow|      
      handle_flow(flow) unless is_instructions?(flow)
    end
    add_footer
    add ['</BillData></Document>']    
    @xml.join('')
  end

  def add_footer
    add "<Footer>"
    add_bill_attribute 'PrintNumber', 'BillPrintNumber'
    add_bill_attribute 'SessionNumber', 'BillSessionNumber'
    add "</Footer>"
  end
  
  def get_pages doc
    pages = (doc/'Page')
    pages.inject({}) do |hash, page|
      handle_page_definition(page, hash)
    end
  end

  def add_bill_attribute name, element_name
    attribute = get_bill_attribute(name)
    add "<#{element_name}>#{attribute}</#{element_name}>" unless attribute.empty?    
  end
    
  def get_tables doc
    tables = (doc/'Tbls/Tbl')
    tables.inject({}) do |hash, table|
      handle_table(table, hash)
    end
  end

  def get_frames doc
    frames = (doc/'AFrames/Frame')
    frames.inject({}) do |hash, frame|
      handle_frame(frame, hash)
    end
  end

  def get_variables doc
    variables = (doc/'VariableFormats/VariableFormat')
    variables.inject({}) do |hash, variable|
      handle_variable(variable, hash)
    end
  end

  def get_bill_attributes doc
    attributes = nil
    (doc/'Element').each do |element|      
      attributes = (element/'Attributes/Attribute') if clean(element.at('ETag/text()')) == "Bill"
    end
    attributes
  end
  
  def get_bill_attribute attrib
    attrib_value = ""
    unless @bill_attributes.nil?
      @bill_attributes.each do |attribute|
        if clean(attribute.at('AttrName/text()')) == attrib
          attrib_value =  clean(attribute.at('AttrValue/text()'))
        end
      end
    end
    attrib_value
  end
  
  def handle_page_definition page_xml, pages
    page = MifPage.new
    page.unique_id = page_xml.at('Unique/text()').to_s
    page.page_type = page_xml.at('PageType/text()').to_s
    page.page_num = clean(page_xml.at('PageNum')) if page_xml.at('PageNum')
    
    page_id = page_xml.at('TextRect[1]/ID/text()').to_s
    pages[page_id] = page    
    pages
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
    vars
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
    frames
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
    
    tables
  end

  def handle_text_rect text_rect
    text_rect_id = text_rect.inner_text

    if (page = @pages[text_rect_id])
      page_start = %Q|<PageStart id="#{page.unique_id}" PageType="#{page.page_type}" PageNum="#{page.page_num}">Page #{page.page_num}</PageStart>|
      @line_num = 0
      
      if @after_first_page
        at_beginning_of_paragraph = @strings.empty? && @xml.last && @xml.last.include?('PgfNumString')

        if at_beginning_of_paragraph
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

          add page_start
          add pgf_start_tag
          add pgf_num_string if pgf_num_string
          lines.reverse.each {|line| add line}
        else
          add_to_last_line page_start
        end
      else
        @first_page = page_start
      end
      
      @pages.delete(text_rect_id)
      @in_page = true
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

  MOVE_OUTSIDE = %w[Amendment Amendment.Number Amendment.Text      
      ClauseTitle Clause Clauses.ar Clause.ar ClauseText 
      Committee Resolution SubSection
      ResolutionHead ResolutionText OrderDate OrderHeading 
      Para.sch Para].inject({}){|h,v| h[v]=true; h}
  
  def move_etag_outside_paragraph?(element, tag)
    collapsed = element.at('../Collapsed/text()').to_s == 'Yes'
    @in_paragraph && (collapsed || MOVE_OUTSIDE[tag])
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
    attributes = get_attributes(@e_tag == 'Clauses.ar' ? (element/'Attributes') : element)

    if move_etag_outside_paragraph?(element, tag)
      move_etag_outside_paragraph tag, uid, attributes
    else
      start_tag = %Q|<#{tag} id="#{uid}"#{attributes}>|
      if @e_tag == 'Bold'
        add_to_last_line start_tag
      else
        add start_tag
      end
      @opened_in_paragraph[tag] = true if @in_paragraph
    end
    
    if !@after_first_page && @first_page
      add @first_page
      @after_first_page = true
    end
  end

  def handle_para
    @prefix_end = false
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
    tag = @etags_stack.last
    
    if tag == 'Bold'
      add_to_last_line "</#{tag}>"
      @opened_in_paragraph.delete(tag)
      tag = @etags_stack.pop
    else
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

  def add_paraline_start
    @line_num += 1
    para_line_start = %Q|<ParaLineStart LineNum="#{@line_num}"></ParaLineStart>|

    if @strings.last.blank? && @xml.last.include?('<Number ')
      last_line = @xml.pop
      last_line.sub!('<Number ', "#{para_line_start}<Number ")
      add last_line
    else
      add_to_last_line para_line_start
    end
    @paraline_start = false
    @in_paraline = true
  end
  
  def handle_string element
    add_paraline_start if @paraline_start    
    text = clean(element)
    last_line = @strings.last || ''

    if @prefix_end && text[/^\d+$/] && @e_tag      
      if (type = last_line[/(Clause|Schedule)/, 1])
        text = %Q|<#{type}_number>#{text}</#{type}_number>|
      else
        text = %Q|<#{@e_tag}_number>#{text}</#{@e_tag}_number>|
      end
    end

    add_to_last_line text
  end
  
  def handle_char element
    add_to_last_line get_char(element)
  end
  
  def flush_strings
    if @strings.size == 1
      last_line = @xml.pop
      text = @strings.pop
      text_tag = @etags_stack.last
      
      if (@last_was_pdf_num_string || text_tag == "ResolutionText") && !text[/^<(PageStart)/]
        last_line += "<#{text_tag}_text>#{text}</#{text_tag}_text>"
      else
        last_line += text
      end
      add last_line

    elsif @strings.size > 1
      raise 'why is strings size > 1? ' + @strings.inspect
    end
  end
  
  def handle_para_line element
    @paraline_start = true
  end

  def handle_a_table element
    table_id = element.at('text()').to_s
    add @table_list[table_id]
  end

  def handle_a_frame element
    frame_id = element.at('text()').to_s
    add @frame_list[frame_id]
  end

  def handle_variable_name element
    var_id = clean(element.at('text()'))
    add_to_last_line @variable_list[var_id]
  end
  
  def add_to_last_line text
    last_line = @strings.pop || ''
    last_line += text
    @strings << last_line    
  end
  
  def initialize_flow_state
    @pgf_tag = nil
    @e_tag = nil
    @amendment_reference = nil
    @in_paragraph = false
    @prefix_end = false
    @in_page = false
    @first_page = nil
    @after_first_page = false
    @paraline_start = false
    @in_paraline = false    
    @opened_in_paragraph = {}
    @etags_stack = []
    @strings = []
  end
  
  def handle_flow flow
    initialize_flow_state
    flow.traverse_element do |element|
      case element.name
        when 'PgfTag'          
          handle_pgf_tag element
        when 'ETag'          
          handle_etag element
        when 'Char'
          handle_char element
        when 'Para'          
          handle_para
        when 'ParaLine'
          handle_para_line element
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
        when 'TextRectID'
          handle_text_rect element
        when 'ATbl'
          handle_a_table element
        when 'AFrame'
          handle_a_frame element
        when 'VariableName'
          handle_variable_name element
      end
    end
  end

end