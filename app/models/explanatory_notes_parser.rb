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
    @xml << ["<BackCover>#{@back_cover}</BackCover>"]
    @xml << ['</ENData></Document>']
    @xml.join('')
  end

  def initialize_parser
    @doc_started = false

    @bill_title = ""
    @full_bill_title = ""
    @bill_version = ""

    @in_section = false
    @in_clause = false
    @in_clause_range = false
    @in_part = false
    @in_chapter = false
    @in_schedule = false
    @in_topic = false

    @in_header = false
    @in_footer = false
    @in_toc = false
    
    @in_cover_page = false
    @back_cover = ""
    
    @blank_row_count = 0
    @page_line_count = 0
    @blank_rows_after_header = 0
    @serial_number = 1
  end

  def handle_page_headers line
    if line.strip[0..23] == 'These notes refer to the' || line.strip[0..24] == 'These notes relate to the'
      @in_header = true
      set_bill_title(line.strip) if @bill_title == ""
    end

    if @in_header
      if line.strip == ""
        @in_header = false
        last_line = @xml.pop
        @xml << last_line unless last_line.strip == ""
        @page_line_count = 0
        @blank_rows_after_header = 0
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

    if @in_toc && line.strip == ""
      if @blank_rows_after_header < 4
        @blank_rows_after_header += 1
      else
        @in_toc = false
        @was_toc = true
      end
    end
  end

  def set_bill_title line
    title = line.gsub('These notes refer to the ', '')
    title = title.gsub('These notes relate to the ', '')
    if title =~ /(.* Bill)/
      @bill_title = $1
    end
    if title =~ /(.* Bill .*\])/
      @full_bill_title = $1
    else
      @full_bill_title = @bill_title
    end
  end

  def set_bill_version line
    if line =~ /\[Bill (.*)\]/
      @bill_version = $1
    elsif line =~ /\[HL Bill (.*)\]/
      @bill_version = $1
    end
  end
  
  def is_en_header line
    if line.strip =~ /^\(.*\)$/ && line.strip == line.strip.upcase
      last_line = @xml.pop
      @xml << last_line
      if last_line.strip =~ /^EXPLANATORY NOTES/
        return true
      end
    end
    false
  end

  def is_clause_start line
    if line =~ /^Clause \d+\S*\ {0,1}(: .*)?$/
      if @page_line_count == 1
        @xml << "\n \n"
      end
      if @in_schedule && !@in_topic
        return false
      else
        return true
      end
      last_line = @xml.pop
      if last_line.strip == ""
        @xml << last_line
        return true
      end
      if is_part_start(last_line)
        @xml << last_line
        return true
      end
      if is_chapter_start(last_line)
        @xml << last_line
        return true
      end
      if is_subheading(last_line)
        @xml << last_line
        return true
      end
      if is_en_header(last_line)
        @xml << last_line
        return true
      end
      @xml << last_line
    end
    if line =~ /^Clause \d+\ {0,1}[^\s\.*]$/
      if @page_line_count == 1
        @xml << "\n \n"
      end
      if @in_schedule && !@in_topic
        return false
      else
        return true
      end
    end
    false
  end

  def is_schedule_start line
    if line =~ /^Schedule \d+\S*(: .*)?$/
      if @page_line_count == 1
        @xml << "\n \n"
        return true
      end
      last_line = @xml.pop
      if last_line.strip == ""
        prev_line = @xml.pop
        @xml << prev_line
        @xml << last_line
        unless prev_line.strip[-1..-1] == ":"
          return true
        end
        if last_line =~ /^Schedule/
          return false
        end
      end
      if is_part_start(last_line)
        @xml << last_line
        return true
      end
      if is_chapter_start(last_line)
        @xml << last_line
        return true
      end
      if is_subheading(last_line)
        @xml << last_line
        return true
      end
      if is_en_header(last_line)
        @xml << last_line
        return true
      end
      @xml << last_line
    end
    false
  end


  def is_chapter_start line
    if line =~ /^Chapter \d+\S*(: .*)?$/
      if @page_line_count == 1
        @xml << "\n \n"
        return true
      end
      last_line = @xml.pop
      if last_line.strip == ""
        @xml << last_line
        return true
      end
      if last_line.strip =~ /\<Chapter /
        @xml << last_line
        return true
      end
      if is_part_start(last_line)
        @xml << last_line
        return true
      end
      if is_en_header(last_line)
        @xml << last_line
        return true
      end
      @xml << last_line
    end
    false
  end

  def is_part_start line
    if line =~ /^Part \d+\S*(: .*)?$/
      if @page_line_count == 1
        @xml << "\n \n"
        return true
      end
      last_line = @xml.pop
      if last_line.strip == ""
        prev_line = @xml.pop
        @xml << prev_line
        @xml << last_line
        unless prev_line.strip[-1..-1] == ":"
          return true
        end
      end
      if last_line.strip =~ /^<Part/
        prev_line = @xml.pop
        @xml << prev_line
        if prev_line == "" || prev_line == "</Part>"
          @xml << last_line
          return true
        end
      end
      if is_en_header(last_line)
        @xml << last_line
        return true
      end
      @xml << last_line
    end
    false
  end
  
  def is_subheading line
    if line.strip == ""
      return false
    end
    if line.strip =~ /^\d*\./
      return false
    end
    if line.strip =~ /^Part \d+\S*(: .*)?$/
      return false
    end
    if line.strip =~ /^Clause \d+\S*(: .*)?$/
      return false
    end
    if line.strip =~ /^Schedule \d+\S*(: .*)?$/
      return false
    end
    if line.strip =~ /^Chapter \d+\S*(: .*)?$/
      return false
    end
    
    last_line = @xml.pop
    if last_line.strip == ""
      prev_line = @xml.pop
      @xml << prev_line
      @xml << last_line
      unless prev_line.strip[-1..-1] == ":"
        return true
      end
    end
    if is_en_header(last_line)
      @xml << last_line
      return true
    end
    @xml << last_line
    false
  end
  
  def handle_clause number
    insert_heading = false
    
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      last_line = @xml.pop
      if is_subheading(last_line)
        insert_heading = true
      else
        @xml << last_line
      end
      add "</Clause>"
    end
    if @in_schedule
      add "</Schedule>"
      @in_schedule = false
    end
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end
    
    if number =~ /([^:]*):*/
      number = $1
    end

    add_section_start('Clause', @serial_number, number)
    @serial_number += 1
    @xml << last_line if insert_heading
    @in_clause = true
  end
  
  def handle_clause_range first_clause, last_clause
    insert_heading = false
    
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      last_line = @xml.pop
      if is_subheading(last_line)
        insert_heading = true
      else
        @xml << last_line
      end
      add "</Clause>"
      @in_clause = false
    end
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end
    
    @in_clause_range = true
    @range_end = last_clause
        
    add (%Q|<ClauseRange start="#{first_clause}" end="#{last_clause}">|)
    
    @xml << last_line if insert_heading
  end

  def handle_schedule number
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    
    if @in_clause
      add "</Clause>"
      @in_clause = false
      if @in_chapter
        add "</Chapter>"
        @in_chapter = false
      end
      if @in_part
        add "</Part>"
        @in_part = false
      end
    end
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end

    if @in_schedule
      add "</Schedule>"
    end
    
    if number =~ /([^:]*):*/
      number = $1
    end

    add_section_start('Schedule', @serial_number, number)
    @serial_number += 1
    @in_schedule = true
  end

  def handle_chapter number
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      add "</Clause>"
      @in_clause = false
    end
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end
    if @in_schedule
      add "</Schedule>"
      @in_schedule = false
    end
    if @in_chapter
      add "</Chapter>"
    end

    if number =~ /([^:]*):*/
      number = $1
    end

    add_section_start('Chapter', @serial_number, number)
    @serial_number += 1
    @in_chapter = true
  end

  def handle_part number
    if @in_schedule
      return
    end
    if @in_section
      add "</TextSection>"
      @in_section = false
    end
    if @in_clause
      add "</Clause>"
      @in_clause = false
    end
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end
    if @in_chapter
      add "</Chapter>"
      @in_chapter = false
    end
    if @in_part
      add "</Part>"
      @in_part = false
    end
    
    if number =~ /([^:]*):*/
      number = $1
    end
    
    unless @in_schedule
      add_section_start('Part', @serial_number, number)
      @serial_number += 1
      @in_part = true
    end
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
    if @in_clause_range
      add "</ClauseRange>"
      @in_clause_range = false
    end
    if @in_chapter
      add "</Chapter>"
    end
    if @in_part
      add "</Part>"
    end
    if @in_schedule
      add "</Schedule>"
    end
  end

  def add_section_start tag, serial, number = ""
    add_bill_info unless @doc_started
    if number == ""
      num_attr = ""
    else
      num_attr = %Q| Number="#{number}"|
    end
    add %Q|<#{tag}#{num_attr} SerialNumber="#{serial}">|
  end

  def add_bill_info
    unless @doc_started
      add "<BillInfo><Title>#{@bill_title}</Title><Version>#{@bill_version}</Version></BillInfo>"
      @doc_started = true
    end
  end

  def check_for_cover_page line 
    #if the current line matches the bill name, we've hit the cover (back page)
    if @full_bill_title.upcase == line.strip
      @in_cover_page = true
    elsif @bill_title.upcase.include?(line.strip) && line.strip != "" 
      #check for a 2 line title
      last_line = @xml.pop
      if @bill_title.upcase.include?(last_line.strip) && last_line.strip != ""
        if last_line.strip + ' ' + line.strip == @full_bill_title.upcase
          @in_cover_page = true
        elsif @bill_title.upcase.include?(last_line.strip) && last_line.strip != ""
          #check for a 3 line title
          last_line2 = @xml.pop
          if last_line2.strip + ' ' + last_line.strip + ' ' + line.strip == @full_bill_title.upcase
            @in_cover_page = true
          else
            @xml << last_line2
            @xml << last_line
          end
        end
      else
        @xml << last_line
      end    
    end
  end

  def handle_txt_line line
    handle_page_headers(line)
    handle_page_footers(line)
    unless @in_header || @in_footer
      handle_toc(line)
    end

    unless @in_header || @in_toc || @in_footer
      if line.strip == ""
        @blank_row_count += 1
      else
        @blank_row_count = 0
      end
      
      case line.strip
        when /^Clause (.*)/
          handle_clause($1) if is_clause_start(line.strip)
        when /^Schedule (.*)/
          handle_schedule($1) if is_schedule_start(line.strip)
        when /^Part (.*)/
          handle_part($1) if is_part_start(line.strip)
        when /^Chapter (.*)/
          handle_chapter($1) if is_chapter_start(line.strip)
        when /^Clauses (.*) to (.*):/
          handle_clause_range($1, $2)
        when /^Topic (.*):/
          @in_topic = true
      end

      unless @in_clause || @in_schedule || @in_part || @in_chapter || @in_section || @in_clause_range
        add_section_start('TextSection', @serial_number)
        @serial_number += 1
        @in_section = true
      end

      if @in_clause || @in_schedule || @in_clause_range
        check_for_cover_page(line)
      end

      text = HTMLEntities.new.encode(line, :decimal)
      text = strip_control_chars(text)
      
      add "#{text}\n" unless @blank_row_count > 1 || @in_cover_page
      if @in_cover_page
        @back_cover << "#{text}\n"
      end
      @page_line_count += 1
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