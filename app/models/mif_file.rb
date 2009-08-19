require 'hpricot'

class MifFile < ActiveRecord::Base
  
  belongs_to :bill

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
        file.set_bill_title(bill_name) if file.bill_id.nil? && bill_name
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
        
        yield [file, title]
      end
    end
  end

  def set_bill_title text
    text = text.chomp(' [HL]')
    if text[/Bill$/]
      bill = Bill.from_name text
      logger.info "  setting bill: #{text}"
      self.bill_id = bill.id
      self.save
    end
  end

  def haml_template_exists?
    File.exist?(haml_template) && html_page_title
  end
  
  def haml_template
    results_dir = RAILS_ROOT + '/app/views/results'
    Dir.mkdir results_dir unless File.exist?(results_dir)
    "#{results_dir}/#{path.gsub('/','_').gsub('.','_')}.haml"
  end
  
  def convert_to_haml
    xml = MifParser.new.parse path
    set_html_page_title(xml)
    result = MifToHtmlParser.new.parse_xml xml, :format => :haml, :body_only => true
    File.open(haml_template, 'w+') {|f| f.write(result) }
  end

  def convert_to_text
    xml = MifParser.new.parse path
    result = MifToHtmlParser.new.parse_xml xml, :format => :text, :body_only => true
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

    def make_title xml, display_type, xpath
      text_item(xml, 'BillData/BillTitle/text()') + " (#{display_type})"
    end

    def set_html_page_title xml
      type = helper.document_type(path)
      display_type = type.sub('_', ' ').gsub(/\b\w/){$&.upcase}
      if display_type == 'Marshalled List'
        display_type << ' of Amendments'
      elsif display_type == 'Consideration'
        display_type << ' of Bill'
      end

      self.html_page_title = case type
        when /^(clauses|cover|arrangement)$/
          make_title xml, display_type, 'BillData/BillTitle/text()'
        when /^(amendment_paper|marshalled_list)$/
          make_title xml, display_type, 'CommitteeShorttitle/STText/text()'
        when 'consideration'
          make_title xml, display_type, 'Head/HeadAmd/Shorttitle/text()'
        else
          display_type
      end
      save!
    end

    def set_name
      logger.info "creating: #{path}"
      self.name = File.basename(path, ".mif") if path
    end

end
