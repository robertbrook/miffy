require 'hpricot'

class MifFile < ActiveRecord::Base

  belongs_to :bill

  validates_uniqueness_of :path
  validates_presence_of :path, :name

  before_validation_on_create :set_name

  def escaped_path
    URI.escape(self.path)
  end

  class << self
    def bill_to_paths paths
      directories = paths.collect {|x| File.dirname(x)}.uniq

      bills = directories.inject({}) do |hash, dir|
        cmd = %Q[cd "#{dir}"; grep -A12 "ETag \\`Shorttitle'" *.mif | grep String]
        values = `#{cmd}`
        cmd = %Q[cd "#{dir}"; grep -A1 "<AttrName \\`ShortTitle'" *.mif | grep AttrValue]
        values += `#{cmd}`
        cmd = %Q[cd "#{dir}"; grep -A24 "ETag \\`CommitteeShorttitle'" *.mif | grep String]
        values += `#{cmd}`
        parse_bill_titles(values, dir) do |file, title|
          if hash[file]
            hash[file] += title
          else
            hash[file] = title
          end
        end
        hash
      end
      bills
    end

    def load paths
      bills = bill_to_paths paths

      paths.collect do |path|
        file = find_or_create_by_path(path)
        if file.file_type.nil?
          parts = path.split("/")
          filename = parts.pop
          filedir = parts.join("/")
          file_type = get_file_type(filedir, filename)
          file.set_date_or_bill_number(filedir, filename)
        end

        bill_name = bills[path]
        if file_type == 'Endorsement'
          set_bill_version(filedir, filename, bill_name)
        end
        if path.include?('Finance_Clauses.xml')
          bill_name = 'Finance Bill 2009'
          file_type = 'Clauses'
        end

        file.set_bill_title(bill_name) if file.bill_id.nil? && bill_name
        file.set_file_type(file_type) if file.file_type.nil? && file_type

        file
      end
    end

    def parse_bill_titles lines, dir
      lines.each_line do |line|
        return if line.blank?
        parts = line.split('.mif')
        file = "#{dir}/#{parts[0].strip}.mif"
        title = parts[1][/(String|AttrValue) `([^']+)'/, 2].chomp(', as amended')
        title = title.split.collect {|x| x.capitalize}.join(' ') if title[/^[A-Z ]+$/]
        title.sub!(/\sbill/i, ' Bill')
        if title[0..0][/[a-z]/]
          title = title[0..0].upcase + title[1..(title.length-1)]
        end
        if title == "Finance Bill"
          title = append_year_to_title(title, dir, "#{parts[0].strip}.mif")
        end
        yield [file, title]
      end
    end

    def append_year_to_title title, dir, filename
      cmd = %Q[cd "#{dir}"; grep -A2 "AttrName \\`CopyrightYear'" '#{filename}' | grep AttrValue]
      values = `#{cmd}`
      if values == ''
        values = get_date(dir, filename)
      end
      year = ""
      if values[/.*(\d\d\d\d).*/]
        title += " #{$1}"
      end
      title
    end

    def set_bill_version(dir, filename, bill_name)
      cmd = %Q[cd "#{dir}";  grep -A30 "<String \\`to be Printed'>" '#{filename}' | grep "<String"]
      values = `#{cmd}`
      values = values.split("\r\n")
      values.each do |value|
        value = value.strip!.gsub!("<String \`","").gsub!("'>","")
      end
      values.reverse!.pop
      printed_date = values.reverse!.join.gsub(", ","")

      bill_number = MifFile.get_print_number(dir, filename)
      session_number = MifFile.get_session_number(dir, filename)

      cmd = %Q[cd "#{dir}";  grep -A1 "<AttrName \\`House'>" '#{filename}' | grep "<AttrValue"]
      values = `#{cmd}`
      house = values.gsub("<AttrValue \`", '').gsub("'>", "").strip

      bill_name = bill_name.chomp(' [HL]')
      if bill_name[/Bill$/] or bill_name[/Bill \d\d\d\d$/]
        bill = Bill.from_name bill_name
        version = Version.create!(
          :printed_date => printed_date,
          :bill_number => bill_number,
          :session_number => session_number,
          :house => house,
          :bill_id => bill.id
        )
      end
    end

    def get_file_type dir, filename
      cmd = %Q[cd "#{dir}"; grep -A1 "<PDFBookInfo " '#{filename}']
      values = `#{cmd}`
      unless values == ''
        return "Book File"
      end

      cmd = %Q[cd "#{dir}"; grep -A7 "ETag \\`NoticeOfAmds'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('notices of amendments')
        return "Marshalled List"
      end

      cmd = %Q[cd "#{dir}"; grep -A7 "ETag \\`Stageheader'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('consideration of bill')
        cmd = %Q[cd "#{dir}"; grep -A7 "ETag \\`Date'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Report"
        end
        cmd = %Q[cd "#{dir}"; grep -A7 "PgfTag \\`Header'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Report"
        end

        return "Report"
      end

      cmd = %Q[cd "#{dir}"; grep -A12 "ETag \\`Stageheader'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('committee')
        cmd = %Q[cd "#{dir}"; grep -A7 "ETag \\`Day'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Amendments"
        end

        return "Amendments"
      end

      cmd = %Q[cd "#{dir}"; grep -A1 "ETag \\`WordsOfEnactment'" '#{filename}']
      values = `#{cmd}`
      unless values == ''
        return "Clauses"
      end

      cmd = %Q[cd "#{dir}"; grep -A2 "<ElementBegin" '#{filename}' | grep "ETag \\`Arrangement'"]
      values = `#{cmd}`
      unless values == ''
        return "Arrangement"
      end

      cmd = %Q[cd "#{dir}"; grep -A5 "PgfTag \\`SchedulesTitle'" '#{filename}' | grep ETag]
      values = `#{cmd}`
      unless values == ""
        return "Schedules"
      end

      cmd = %Q[cd "#{dir}"; grep -A1 "ETag \\`Endorse'" '#{filename}']
      values = `#{cmd}`
      unless values == ''
        return "Endorsement"
      end

      cmd = %Q[cd "#{dir}"; grep -A1 "ETag \\`Cover'" '#{filename}']
      values = `#{cmd}`
      unless values == ''
        return "Cover"
      end

      return "Other"
    end

    def get_date dir, filename
      values = ""
      cmd = %Q[cd "#{dir}"; grep -A8 "ETag \\`Date.text'" '#{filename}' | grep String]
      values += `#{cmd}`
      if values == ''
        cmd = %Q[cd "#{dir}"; grep -A8 "ETag \\`Day'" '#{filename}' | grep String]
        values += `#{cmd}`
      end
      if values == ''
        cmd = %Q[cd "#{dir}"; grep -A8 "ETag \\`Date'" '#{filename}' | grep String]
        values += `#{cmd}`
      end
      values
    end

    def get_print_number dir, filename
      cmd = %Q[cd "#{dir}";  grep -A1 "<AttrName \\`PrintNumber'>" '#{filename}' | grep "<AttrValue"]
      values = `#{cmd}`
      values.gsub("<AttrValue \`", '').gsub("'>", "").gsub("HL ", "").gsub("Bill ", "").strip
    end

    def get_session_number dir, filename
      cmd = %Q[cd "#{dir}";  grep -A1 "<AttrName \\`SessionNumber'>" '#{filename}' | grep "<AttrValue"]
      values = `#{cmd}`
      values.gsub("<AttrValue \`", '').gsub("'>", "").strip
    end

  end

  def set_file_type text
    self.file_type = text
    self.save
  end

  def set_date_or_bill_number dir, filename
    printed_date = MifFile.get_date(dir, filename)
    if printed_date == ''
      session_number = MifFile.get_session_number(dir, filename)
      print_number = MifFile.get_print_number(dir, filename)
      self.session_number = session_number unless session_number == ""
      self.bill_number = print_number unless print_number == ""
      self.save unless print_number == "" and session_number == ""
    else
      self.printed_date = printed_date
      self.save
    end
  end

  def set_bill_title text
    text = text.chomp(' [HL]')
    if text[/Bill$/] or text[/Bill \d\d\d\d$/]
      bill = Bill.from_name text
      logger.info "  setting bill: #{text}"
      self.bill_id = bill.id
      self.save
    end
  end

  # options
  # :interleave_notes => true (defaults to false)
  # :force => true (defaults to false)
  def convert_to_haml options={}
    do_convert_to_haml(options) if !haml_template_exists?(options) || options[:force]
    haml_template(options)
  end

  def convert_to_text
    xml = MifParser.new.parse path
    result = MifToHtmlParser.new.parse_xml xml, :format => :text, :body_only => true
  end

  def clauses_file
    if bill
      file = bill.clauses_file
      if file.blank? || file == self
        nil
      else
        file.path
      end
    else
      path
    end
  end

  def has_explanatory_notes?
    bill && bill.has_explanatory_notes?
  end
  
  def has_effects?
    bill && bill.has_effects?
  end
  
  def haml_template_exists? options={}
    File.exist?(haml_template(options)) && html_page_title
  end

  private

    def convert_to_xml
      case File.extname(path)
        when '.mif'
          MifParser.new.parse(path)
        when '.xml'
          IO.read(path)
        else
          raise "unrecognized path: #{path}"
      end
    end

    def do_convert_to_haml options
      haml_file_name = haml_template(options)
      File.delete(haml_file_name) if File.exists?(haml_file_name)
      xml = convert_to_xml
      File.open("#{RAILS_ROOT}/tmp/example.xml", 'w+') {|f| f.write(xml) } if RAILS_ENV == 'development'
      set_html_page_title(xml)
      xml = ActReferenceParser.new.parse_xml(xml)
      File.open("#{RAILS_ROOT}/tmp/example.act.xml", 'w+') {|f| f.write(xml) } if RAILS_ENV == 'development'

      options = {:clauses_file => clauses_file,
          :format => :haml, :body_only => true,
          :interleave_notes => options[:interleave_notes],
          :effects => options[:effects]}
      unless options[:clauses_file]
        options.merge!({:clauses_file => File.dirname(path)+'/Clauses.mif' })
      end

      result = MifToHtmlParser.new.parse_xml xml, options

      File.open(haml_file_name, 'w+') {|f| f.write(result) }
    end

    def results_dir
      results_dir = RAILS_ROOT + '/app/views/results'
      Dir.mkdir results_dir unless File.exist?(results_dir)
      results_dir
    end

    def haml_template options
      en_suffix = options[:interleave_notes] ? '_interleave' : ''
      "#{results_dir}/#{path.gsub('/','_').gsub('.','_')}#{en_suffix}.haml"
    end

    class Helper
      include Singleton
      include ApplicationHelper
    end

    def helper
      Helper.instance
    end

    def text_item xml, xpath
      doc = Hpricot.XML xml.to_s
      (doc/xpath).to_s
    end

    def set_html_page_title xml
      type = helper.document_type(path)
      display_type = type.sub('_', ' ').gsub(/\b\w/){$&.upcase}
      if display_type == 'Marshalled List'
        display_type << ' of Amendments'
      elsif display_type == 'Consideration'
        display_type << ' of Bill'
      end

      self.html_page_title = Bill.find_by_id(bill_id).name + " (#{display_type})" if bill_id

      save!
    end

    def set_name
      self.name = File.basename(path, ".mif") if path
    end

end
