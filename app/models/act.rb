require 'open-uri'
require 'hpricot'

class Act < ActiveRecord::Base

  validates_presence_of :name, :opsi_url, :legislation_url
  before_validation :populate_year, :populate_number, :populate_title, :populate_opsi_url, :populate_legislation_url

  class << self
    def from_name name
      if act = find_by_name(name)
        act.populate_opsi_url unless act.opsi_url?
        act
      else
        create! :name => name
      end
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

  def populate_year
    if year.blank?
      if name[/Act\s(\d\d\d\d)/]
        self.year = $1
      end
    end
  end

  def populate_number
    if number.blank?
      if name[/\(c\.\s?(\d+)/]
        self.number = $1
      end
    end
  end

  def populate_title
    if title.blank?
      if name[/^(.+)\s\(c\.\s?\d+.+$/]
        self.title = $1
      end
    end
  end

  def populate_legislation_url
    if legislation_url.blank?
      number_part = number? ? "&number=#{number}" : ''
      act_title = title.blank? ? name : title
      search_url = "http://www.legislation.gov.uk/id?title=#{URI.escape(act_title)}#{number_part}"
      begin
        doc = Hpricot.XML open(search_url)
        url = nil

        if doc && doc.at('Legislation')
          self.legislation_url = doc.at('Legislation')['DocumentURI']
        end
      rescue Exception => e
        warn 'error retrieving: ' + search_url
        warn e.class.name
        warn e.to_s
      end
    end
  end

  def populate_opsi_url force=false
    do_search = (force || opsi_url.blank?)
    if do_search
      search_url = "http://search.opsi.gov.uk/search?q=#{URI.escape(name)}&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection"
      begin
        doc = Hpricot.XML open(search_url)
        url = nil

        (doc/'R/T').each do |result|
          unless url
            term = result.inner_text.gsub(/<[^>]+>/,'').strip
            url = result.at('../U/text()').to_s if(name == term || term.starts_with?(title))
          end
        end

        self.opsi_url = url
      rescue Exception => e
        warn 'error retrieving: ' + search_url
        warn e.class.name
        warn e.to_s
      end
    end
  end
end
