require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'htmlentities'

class MifParser

  VERSION = "0.0.0"

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
    flows = (doc/'TextFlow')

    xml = [options[:html] ? '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>' : '<Document>']
    flows.each do |flow|
      unless is_instructions?(flow)
        if options[:html]
          handle_flow_to_html(flow, xml)
        else
          handle_flow(flow, xml)
        end
      end
    end
    xml << [options[:html] ? '</body></html>' : '</Document>']
    xml.join('')
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

  def get_html_for_char element
    char = get_char(element)
    if char == "\n"
      "<br />"
    else
      HTMLEntities.new.encode(char)
    end
  end

  def handle_etag element, xml
    tag = clean(element)
    @stack << tag
    uid = element.at('../Unique/text()').to_s
    collapsed = element.at('../Collapsed/text()').to_s == 'Yes'
    if (collapsed || (tag == 'ClauseText')) && @in_paragraph #
      line = xml.pop
      lines = []
      while !line.include?(@pgf_tag)
        if line[/PgfNumString/]
          pgf_num_string = line
        else
          lines << line
        end
        line = xml.pop
      end
      pgf_start_tag = line
      lines.each {|line| add line}
      add "<#{tag} id='#{uid}'>"
      add pgf_start_tag
      puts uid if pgf_num_string.nil?
      puts tag if pgf_num_string.nil?
      add pgf_num_string
      @opened_in_paragraph.clear
    else
      add "<#{tag} id='#{uid}'>"
      @opened_in_paragraph[tag] = true if @in_paragraph
    end
  end

  def handle_para xml
    if @in_paragraph
      if @opened_in_paragraph.size > 1
        raise "can not handle all elements opened in <#{@pgf_tag}> paragraph: #{@opened_in_paragraph.keys.inspect}"
      elsif @opened_in_paragraph.size == 1
        last_line = xml.pop
        if last_line.include?(@opened_in_paragraph.keys.first)
          add "</#{@pgf_tag}>\n"
          add last_line
          @pgf_tag = nil
          @in_paragraph = false
          @opened_in_paragraph.clear
        else
          raise "too tricky to close <#{@pgf_tag}> paragraph, opened element: #{@opened_in_paragraph.keys.first} last_line: #{last_line} xml: #{xml.join("\n").reverse[0..1000].reverse}"
        end
      else
        add "</#{@pgf_tag}>\n"
        @pgf_tag = nil
        @in_paragraph = false
        @opened_in_paragraph.clear
      end
    end
  end

  def handle_element_end element, xml
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
          @pgf_tag = clean(element).gsub(' ','_')
        when 'ETag'
          handle_etag element, xml
        when 'Char'
          last_line = xml.pop
          last_line += get_char(element)
          add last_line
        when 'Para'
          handle_para xml
        when 'PgfNumString'
          if @pgf_tag
            add "\n<#{@pgf_tag}>"
            @in_paragraph = true
          end
          string = clean(element)
          add "<PgfNumString>#{string}</PgfNumString>"
        when 'String'
          last_line = xml.pop
          last_line += clean(element)
          add last_line
        when 'ElementEnd'
          handle_element_end element, xml
      end
    end
  end

  DIV = %w[Amendments.Commons Head HeadConsider Date
      Committee Clause.Committee Order.Committee
      CrossHeadingSch Amendment
      NewClause.Committee Order.House].inject({}){|h,v| h[v]=true; h}

  # P = %w[].inject({}){|h,v| h[v]=true; h}

  SPAN = %w[Stageheader CommitteeShorttitle ClausesToBeConsidered
      MarshalledOrderNote SubSection Schedule.Committee
      Para Para.sch SubPara.sch SubSubPara.sch
      Definition
      CrossHeadingTitle Heading.text
      ClauseTitle ClauseText Move TextContinuation
      OrderDate OrderPreamble OrderText OrderPara
      Order.Motion OrderHeading
      OrderAmendmentText
      ResolutionPreamble
      Day Date.text STText Notehead NoteTxt
      Amendment.Text Amendment.Number Number Page Line ].inject({}){|h,v| h[v]=true; h}

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}

  HR = %w[Separator.thick].inject({}){|h,v| h[v]=true; h}

  def handle_flow_to_html(flow, xml)
    stack = []
    paras = []
    flow.traverse_element do |element|
      case element.name
        # when 'Para'
        when 'PgfTag'
          xml << "</p>\n"
          tag = clean(element)
          xml << "<p class='#{tag}'>"
        when 'ETag'
          tag = clean(element)
          stack << tag
          if DIV[tag]
            xml << "<div class='#{tag}'>"
          # elsif P[tag]
            # xml << "<p class='#{tag}'>"
          elsif UL[tag]
            xml << "<ul class='#{tag}'>"
          elsif LI[tag]
            xml << "<li class='#{tag}'>"
          elsif SPAN[tag]
            xml << "<span class='#{tag}'>"
          elsif HR[tag]
            xml << "<!-- page break -->"
          else
            xml << '<div>[['
            xml << tag
            xml << ']]: '
          end
        when 'Char'
          xml << get_html_for_char(element)
        when 'PgfNumString'
          string = clean(element)
          if string
            string.gsub!('\t',' ')
            string = HTMLEntities.new.encode(string)
            xml << "<span class='PgfNumString'>#{string}</span>"
          end
        when 'String'
          string = clean(element)
          if string
            string.gsub!('\t',' ')
            string = HTMLEntities.new.encode(string)
            xml << string
          end
        when 'ElementEnd'
          tag = stack.pop
          if DIV[tag]
            xml << "</div>"
          # elsif P[tag]
            # xml << "</p>"
          elsif UL[tag]
            xml << "</ul>"
          elsif LI[tag]
            xml << "</li>"
          elsif SPAN[tag]
            xml << "</span>"
          elsif HR[tag]
            # xml << ""
          else
            xml << '</div>'
          end
          # xml << name
          # xml << '>'
          xml << "\n" unless tag[/(Day|STHouse|STLords|STText)/]
      end
    end
  end

end