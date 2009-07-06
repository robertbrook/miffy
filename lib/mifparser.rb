require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'htmlentities'
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
        "\n"
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
    xml_file = Tempfile.new("#{mif_file}.xml",'.')
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
    instruction_regexp = /(`Header'|REISSUE|Running H\/F|line of text which is to be numbered|Use the following fragment to insert an amendment line number)/
    flow.inner_text[instruction_regexp] ||
    (flow.at('PgfTag') && flow.at('PgfTag/text()').to_s[/AmendmentLineNumber/])
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    xml = [options[:html] ? '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>' : '<Document>']

    if options[:html]
      doc_to_html(doc, xml)
    else
      flows = (doc/'TextFlow')
      flows.each do |flow|
        unless is_instructions?(flow)
          handle_flow(flow, xml)
        end
      end
    end

    xml << [options[:html] ? '</body></html>' : '</Document>']
    xml = xml.join('')
    begin
      doc = REXML::Document.new(xml)
    rescue Exception => e
      puts e.to_s
    end

    if options[:indent]
      indented = ''
      doc.write(indented,2)
      indented
    else
      xml
    end
  end

  def handle_pgf_tag element
    tag = clean(element).gsub(' ','_')
    @pgf_tag = "#{tag}_PgfTag"
    @pgf_tag_id = element.at('../Unique/text()').to_s

    if tag == 'AmendmentNumber'
      add_pgf_tag
    end
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

  def handle_etag element
    tag = clean(element)
    @stack << tag
    uid = element.at('../Unique/text()').to_s

    attributes = (element/'../Attributes/Attribute')
    attribute_list = ''
    if attributes && attributes.size > 0
      attributes.each do |attribute|
        name = clean(attribute.at('AttrName/text()'))
        value = clean(attribute.at('AttrValue/text()'))
        attribute_list += %Q| #{name}="#{value}"|
      end
    end

    collapsed = element.at('../Collapsed/text()').to_s == 'Yes'
    if @in_paragraph && (collapsed ||
        tag == 'Amendment.Number' ||
        tag == 'ClauseText' ||
        tag == 'Para.sch' )
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
      lines.each {|line| add line}
      add %Q|<#{tag} id="#{uid}"#{attribute_list}>|
      add pgf_start_tag
      # puts uid if pgf_num_string.nil?
      # puts tag if pgf_num_string.nil?
      add pgf_num_string if pgf_num_string
      @opened_in_paragraph.clear
    else
      add %Q|<#{tag} id="#{uid}"#{attribute_list}>|
      @opened_in_paragraph[tag] = true if @in_paragraph
    end
  end

  def handle_para
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
    tag = @stack.pop
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

  def handle_flow flow, xml
    @xml = xml
    @pgf_tag = nil
    @in_paragraph = false
    @opened_in_paragraph = {}
    @stack = []
    flow.traverse_element do |element|
      case element.name
        when 'PgfTag'
          handle_pgf_tag element
        when 'ETag'
          handle_etag element
        when 'Char'
          last_line = @xml.pop
          last_line += get_char(element)
          add last_line
        when 'Para'
          handle_para
        when 'PgfNumString'
          add_pgf_tag
          string = clean(element)
          add "<PgfNumString>#{string}</PgfNumString>"
        when 'String'
          last_line = @xml.pop
          last_line += clean(element)
          add last_line
        when 'ElementEnd'
          handle_element_end element
      end
    end
  end

end