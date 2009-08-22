require 'htmlentities'
require 'tempfile'
require 'rexml/document'

class ExplanatoryNotesParser

  class << self
    def parse pdf_file, options={}
      ExplanatoryNotesParser.new.parse pdf_file, options
    end
  end

  def parse pdf_file, options={}
    pdf_txt_file = Tempfile.new("#{pdf_file.gsub('/','_')}.txt", "#{RAILS_ROOT}/tmp")
    pdf_txt_file.close # was open

    Kernel.system %Q|pdftotext -layout -enc UTF-8 "#{pdf_file}" "#{pdf_txt_file.path}"|

    result = parse_txt_file(pdf_txt_file.path, options)
    pdf_txt_file.delete
    result
  end

  def parse_txt_file doc, options={}
    xml = make_xml(doc)
    begin
      doc = REXML::Document.new(xml)
    rescue Exception => e
      puts e.to_s
      # raise e
    end
    if options[:indent]
      indented = ''
      doc.write(indented,2)
      indented
    else
      xml
    end
  end

  def make_xml doc
    initialize_parser()
    en_text = File.open(doc)

    @xml = ['<Document><ENData>']
    en_text.each do |line|
      handle_txt_line(line)
    end
    do_cleanup
    @xml << ['</ENData></Document>']
    @xml.join('')
  end

  def initialize_parser
    @doc_started = false

    @bill_title = ""
    @bill_version = ""

    @in_section = false
    @in_clause = false
    @in_part = false
    @in_chapter = false
    @in_schedule = false

    @in_header = false
    @in_footer = false
    @in_toc = false
    
    @blank_row_count = 0
  end

  def handle_page_headers line
    if line.strip[0..23] == 'These notes refer to the'
      @in_header = true
      set_bill_title(line.strip) if @bill_title == ""
    end

    if @in_header
      if line.strip == ""
        @in_header = false
        @prev_toc_line = "header"
      else
        set_bill_version(line) if @bill_version == ""
      end
    end
  end

  def handle_page_footers line
    if line.strip =~ /^(\d+)$/
      @in_footer = true
    elsif line.strip =~ /Bill-#{@bill_version}-EN .* (\d*\/\d*)/
      @in_footer = true
    elsif line.strip =~ /HL Bill-#{@bill_version}-EN .* (\d*\/\d*)/
      @in_footer = true
    else
      @in_footer = false
    end
  end

  def handle_toc line
    if line.strip == "TABLE OF CONTENTS"
      @in_toc = true
    end

    if @in_toc
      if line.strip == "" && @prev_toc_line == ""
        @in_toc = false
      end
      if @prev_toc_line == "header"
        @prev_toc_line = "hack for extra spacing after header!"
      else
        @prev_toc_line = line.strip
      end
    end
  end

  def set_bill_title line
    title = line.gsub('These notes refer to the ', '')
    if title =~ /(.* Bill)/
      @bill_title = $1
    end
  end

  def set_bill_version line
    if line =~ /\[Bill (.*)\]/
      @bill_version = $1
    elsif line =~ /\[HL Bill (.*)\]/
      @bill_version = $1
    end
  end

  def handle_clause(number)
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      add "</Clause>"
    end

    add_section_start('Clause', number)
    @in_clause = true
  end

  def handle_schedule
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_schedule
      add "</Schedule>"
    end

    add_section_start('Schedule', number)
    @in_schedule = true
  end

  def handle_chapter(number)
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      add "</Clause>"
      @in_clause = false
    end
    if @in_schedule
      add "</Schedule>"
      @in_schedule = false
    end
    if @in_chapter
      add "</Chapter>"
    end

    add_section_start('Chapter', number)
    @in_chapter = true
  end

  def handle_part(number)
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      add "</Clause>"
      @in_clause = false
    end
    if @in_schedule
      add "</Schedule>"
      @in_schedule = false
    end
    if @in_chapter
      add "</Chapter>"
      @in_chapter = false
    end
    if @in_part
      add "</Part>"
    end

    add_section_start('Part', number)
    @in_part = true
  end

  def add text
    if text.nil?
      raise 'text should not be null'
    else
      @xml << text
    end
  end

  def do_cleanup
    if @in_section
      add "</TextSection>"
    end
    if @in_clause
      add "</Clause>"
    end
    if @in_schedule
      add "</Schedule>"
    end
    if @in_chapter
      add "</Chapter>"
    end
    if @in_part
      add "</Part>"
    end
  end

  def add_section_start tag, number = ""
    add_bill_info unless @doc_started
    if number == ""
      num_attr = ""
    else
      num_attr = %Q| Number="#{number}"|
    end
    add "<#{tag}#{num_attr}>"
  end

  def add_bill_info
    unless @doc_started
      add "<BillInfo><Title>#{@bill_title}</Title><Version>#{@bill_version}</Version></BillInfo>"
      @doc_started = true
    end
  end

  def handle_txt_line line
    if line.strip == ""
      @blank_row_count += 1
    else
      @blank_row_count = 0
    end
    
    handle_page_headers(line)
    handle_page_footers(line)
    unless @in_header || @in_footer
      handle_toc(line)
    end

    unless @in_header || @in_toc || @in_footer
      case line
        when /^Clause ([^:]*): /
          handle_clause($1)
        when /^Schedule ([^:]*): /
          handle_schedule($1)
        when /^Part ([^:]*): /
          handle_part($1)
        when /^Chapter ([^:]*): /
          handle_chapter($1)
      end

      unless @in_clause || @in_schedule || @in_part || @in_chapter || @in_section
        add_section_start('TextSection')
        @in_section = true
      end

      text = HTMLEntities.new.encode(line, :decimal)
      text = strip_control_chars(text)

      if @blank_row_count > 2
        if @in_clause
          add "</Clause>"
          @in_clause = false
        elsif @in_chapter
          add "</Chapter>"
          @in_chapter = false
        elsif @in_part
          add "</Part>"
          @in_part = false
        end
      end
      
      add "#{text}\n" unless @blank_row_count > 1
    end
  end

  private
    def strip_control_chars text
      text.gsub!('&#00;', ' ') #  null character
      text.gsub!('&#1;', ' ') # 	start of header
      text.gsub!('&#2;', ' ') # 	start of text
      text.gsub!('&#3;', ' ') # 	end of text
      text.gsub!('&#4;', ' ') # 	end of transmission
      text.gsub!('&#5;', ' ') # 	enquiry
      text.gsub!('&#6;', ' ') # 	acknowledge
      text.gsub!('&#7;', ' ') # 	bell (ring)
      text.gsub!('&#8;', ' ') # 	backspace
      text.gsub!('&#9;', ' ') # 	horizontal tab
      text.gsub!('&#01;', ' ') # 	start of header
      text.gsub!('&#02;', ' ') # 	start of text
      text.gsub!('&#03;', ' ') # 	end of text
      text.gsub!('&#04;', ' ') # 	end of transmission
      text.gsub!('&#05;', ' ') # 	enquiry
      text.gsub!('&#06;', ' ') # 	acknowledge
      text.gsub!('&#07;', ' ') # 	bell (ring)
      text.gsub!('&#08;', ' ') # 	backspace
      text.gsub!('&#09;', ' ') # 	horizontal tab
      text.gsub!('&#10;', ' ') # 	line feed
      text.gsub!('&#11;', ' ') # 	vertical tab
      text.gsub!('&#12;', ' ') # 	form feed
      text.gsub!('&#13;', ' ') # 	carriage return
      text.gsub!('&#14;', ' ') # 	shift out
      text.gsub!('&#15;', ' ') # 	shift in
      text.gsub!('&#16;', ' ') # 	data link escape
      text.gsub!('&#17;', ' ') # 	device control 1
      text.gsub!('&#18;', ' ') # 	device control 2
      text.gsub!('&#19;', ' ') # 	device control 3
      text.gsub!('&#20;', ' ') # 	device control 4
      text.gsub!('&#21;', ' ') # 	negative acknowledge
      text.gsub!('&#22;', ' ') # 	synchronize
      text.gsub!('&#23;', ' ') # 	end transmission block
      text.gsub!('&#24;', ' ') # 	cancel
      text.gsub!('&#25;', ' ') # 	end of medium
      text.gsub!('&#26;', ' ') # 	substitute
      text.gsub!('&#27;', ' ') # 	escape
      text.gsub!('&#28;', ' ') # 	file separator
      text.gsub!('&#29;', ' ') # 	group separator
      text.gsub!('&#30;', ' ') # 	record separator
      text.gsub!('&#31;', ' ') # 	unit separator
      text.gsub!('&#127;', ' ') # 	delete (rubout)
      text
    end

end