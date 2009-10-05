require 'hpricot'

class MifFile < ActiveRecord::Base

  belongs_to :bill

  validates_uniqueness_of :path
  validates_presence_of :path, :name

  before_validation_on_create :set_name

  class << self
    def load paths
      directories = paths.collect {|x| File.dirname(x)}.uniq
 
      bills = directories.inject({}) do |hash, dir|
        cmd = %Q[cd #{dir}; grep -A12 "ETag \\`Shorttitle'" *.mif | grep String]
        values = `#{cmd}`
        cmd = %Q[cd #{dir}; grep -A1 "<AttrName \\`ShortTitle'" *.mif | grep AttrValue]
        values += `#{cmd}`
        cmd = %Q[cd #{dir}; grep -A24 "ETag \\`CommitteeShorttitle'" *.mif | grep String]
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
      logger.warn bills.inspect
      paths.collect do |path|
        file = find_or_create_by_path(path)
        bill_name = bills[path]

        if file.file_type.nil?
          parts = path.split("/")
          filename = parts.pop
          filedir = parts.join("/")
          file_type = get_file_type(filedir, filename) 
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
      cmd = %Q[cd #{dir}; grep -A2 "AttrName \\`CopyrightYear'" '#{filename}' | grep AttrValue]
      values = `#{cmd}`
      if values == ''
        cmd = %Q[cd #{dir}; grep -A8 "ETag \\`Date.text'" '#{filename}' | grep String]
        values += `#{cmd}`
      end
      if values == ''
        cmd = %Q[cd #{dir}; grep -A8 "ETag \\`Day'" '#{filename}' | grep String]
        values += `#{cmd}`
      end
      if values == ''
        cmd = %Q[cd #{dir}; grep -A8 "ETag \\`Date'" '#{filename}' | grep String]
        values += `#{cmd}`
      end
      year = ""
      if values[/.*(\d\d\d\d).*/]
        title += " #{$1}"
      end
      title
    end
    
    def get_file_type dir, filename
      cmd = %Q[cd #{dir}; grep -A7 "ETag \\`NoticeOfAmds'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('notices of amendments')
        return "Marshalled List"
      end

      cmd = %Q[cd #{dir}; grep -A7 "ETag \\`Stageheader'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('consideration of bill')
        cmd = %Q[cd #{dir}; grep -A7 "ETag \\`Date'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Report"
        end
        cmd = %Q[cd #{dir}; grep -A7 "PgfTag \\`Header'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Report"
        end

        return "Report"
      end

      cmd = %Q[cd #{dir}; grep -A12 "ETag \\`Stageheader'" '#{filename}' | grep String]
      values = `#{cmd}`
      if values.downcase.include?('committee')
        cmd = %Q[cd #{dir}; grep -A7 "ETag \\`Day'" '#{filename}' | grep String]
        values = `#{cmd}`
        if values.downcase.include?('tabled')
          return "Tabled Amendments"
        end

        return "Amendments"
      end

      cmd = %Q[cd #{dir}; grep -A1 "ETag \\`WordsOfEnactment'" '#{filename}']
      values = `#{cmd}`
      unless values == ''
        return "Clauses"
      end

      cmd = %Q[cd #{dir}; grep -A2 "<ElementBegin" '#{filename}' | grep "ETag \\`Arrangement'"]
      values = `#{cmd}`
      unless values == ''
        return "Arrangement"
      end

      cmd = %Q[cd #{dir}; grep -A5 "PgfTag \\`SchedulesTitle'" '#{filename}' | grep ETag]
      values = `#{cmd}`
      unless values == ""
        return "Schedules"
      end

      return "Other"
    end
  end

  def set_file_type text
    self.file_type = text
    self.save
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

  def haml_template_exists?
    File.exist?(haml_template) && html_page_title
  end

  def haml_template explanatory_notes=''
    en_suffix = ''
    unless explanatory_notes.blank?
      en_suffix = "_#{explanatory_notes}"
    end
    results_dir = RAILS_ROOT + '/app/views/results'
    Dir.mkdir results_dir unless File.exist?(results_dir)
    "#{results_dir}/#{path.gsub('/','_').gsub('.','_')}#{en_suffix}.haml"
  end

  def convert_to_haml explanatory_notes=''
    if File.extname(path) == '.mif'
      xml = MifParser.new.parse path
    elsif File.extname(path) == '.xml'
      xml = IO.read(path)
    else
      raise "unrecognized path: #{path}"
    end

    set_html_page_title(xml)
    xml = ActReferenceParser.new.parse_xml(xml)
    result = MifToHtmlParser.new.parse_xml xml, :clauses_file => clauses_file, :format => :haml, :body_only => true, :ens => explanatory_notes
    File.open(haml_template(explanatory_notes), 'w+') {|f| f.write(result) }
  end

  def convert_to_text
    xml = MifParser.new.parse path
    result = MifToHtmlParser.new.parse_xml xml, :format => :text, :body_only => true
  end

  def clauses_file
    file = bill.clauses_file
    if file.blank? || file == self
      nil
    else
      file.path
    end
  end

  private

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

      self.html_page_title = Bill.find_by_id(self.bill_id).name + " (#{display_type})"
      save!
    end

    def set_name
      self.name = File.basename(path, ".mif") if path
    end

end
