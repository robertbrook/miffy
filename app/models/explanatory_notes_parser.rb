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

      add line.gsub('&', 'amp;')
    end
  end

end