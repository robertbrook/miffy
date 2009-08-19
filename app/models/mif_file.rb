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
  
  def convert_to_haml
    haml = ActToHtmlParser.new.parse_xml_file path, :format => :haml, :body_only => true
    
    results_dir = RAILS_ROOT + '/app/views/results'
    Dir.mkdir results_dir unless File.exist?(results_dir)
    template = "#{results_dir}/#{path.gsub('/','_').gsub('.','_')}.haml"
    
    File.open(template,'w+') {|f| f.write(haml) }
    template
  end

  private

    def set_name      
      logger.info "creating: #{path}"
      $stdout.flush
      self.name = path.split('/').last.chomp('.mif') if path
    end

end
