require 'open-uri'
require 'morph'
require 'hpricot'
require 'legislation_uk'

class Act < ActiveRecord::Base

  has_many :act_parts, :dependent => :delete_all
  has_many :act_sections, :dependent => :delete_all, :order => 'section_number + 0 ASC'

  validates_presence_of :name
  validates_uniqueness_of :legislation_url, :allow_nil => true

  before_validation :normalize_name, :populate_year, :populate_number, :populate_title,
      :populate_legislation_urls, :populate_act_sections

  class << self
    def get_title name
      if name[/^(.+)\s\(c\.\s?\d+.+$/]
        $1
      else
        name
      end
    end

    def get_number name
      name[/\(c\.\s?(\d+)/, 1]
    end

    def get_legislation_from_name name
      get_legislation(get_title(name), get_number(name))
    end

    def get_legislation title, number=nil
      return nil # while legislation.gov.uk is down
      if number
        puts "calling Legislation API with title and number - searching for #{title} / #{number}" unless RAILS_ENV == "test"
        Legislation::UK.find(title, number)
      else
        puts "calling Legislation API with title - searching for #{title}" unless RAILS_ENV == "test"
        Legislation::UK.find(title)
      end
    end

    def normalize_name name
      name = name.squeeze(' ')
      name.sub!(/\(c\.(\d)/, '(c. \1')
      name
    end

    def from_name name
      name = normalize_name(name) if name
      if act = find_by_name(name)
        act.save if act.opsi_url.blank?
        act
      elsif act = find_by_title(name)
        act.save if act.opsi_url.blank?
        act
      elsif legislation = get_legislation_from_name(name)
        act = find_by_legislation_url(legislation.legislation_uri)
        if act
          act
        else
          warn "creating from name: #{name}" unless RAILS_ENV == "test"
          create! :name => name
        end
      else
        warn "creating from name: #{name}" unless RAILS_ENV == "test"
        create! :name => name
      end
    end
  end

  def find_section_by_number section_number
    act_sections.find_by_section_number section_number
  end

  def convert_to_haml
    haml = ActToHtmlParser.new.parse_xml_file path, :format => :haml, :body_only => true

    results_dir = RAILS_ROOT + '/app/views/results'
    Dir.mkdir results_dir unless File.exist?(results_dir)
    template = "#{results_dir}/#{path.gsub('/','_').gsub('.','_')}.haml"

    File.open(template,'w+') {|f| f.write(haml) }
    template
  end

  def normalize_name
    self.name = Act.normalize_name(name) if name
  end

  def populate_year
    if year.blank? && name[/Act\s(\d\d\d\d)/]
      self.year = $1
    end
  end

  def populate_number
    self.number = Act.get_number(name) if number.blank?
  end

  def populate_title
    self.title = Act.get_title(name) if title.blank?
  end

  def get_legislation
    if @legislation
      @legislation
    else
      @legislation = Act.get_legislation title, number
    end
  end

  def populate_legislation_urls
    if legislation_url.blank?
      if legislation = get_legislation
        self.legislation_url = legislation.legislation_uri
        self.opsi_url = legislation.opsi_uri
        self.statutelaw_url = legislation.statutelaw_uri
      else
        populate_legislation_urls_via_opsi
      end
    end
  end

  def create_act_part part
    unless part.respond_to?(:title)
      logger.warn "title not present on: #{part.inspect}"
    else
      begin
        logger.info "creating #{part.title}"
      rescue
        logger.warn "act part is nil" if part.nil?
        return
      end
    end
    act_part = act_parts.build :name => part.number,
        :title => part.title,
        :legislation_url => part.legislation_uri,
        :statutelaw_url => part.statutelaw_uri

    part.sections.each do |section|
      unless section.respond_to?(:title)
        logger.warn "title not present on: #{section.inspect}"
      else
        begin
          act_sections.build :number => section.section_number,
              :title => section.title,
              :act_part => act_part,
              :legislation_url => section.legislation_uri,
              :opsi_url => section.opsi_uri,
              :statutelaw_url => section.statutelaw_uri
        rescue
          logger.warn "act section is nil" if section.nil?
          return
        end
      end
    end
  end

  def create_act_section section
    if section
      opsi_uri = section.opsi_uri
      act_sections.build :number => section.section_number,
          :title => section.title,
          :legislation_url => section.legislation_uri,
          :opsi_url => opsi_uri,
          :statutelaw_url => section.statutelaw_uri
    end
  end

  def populate_act_sections
    if act_sections.empty?
      if legislation = get_legislation
        if legislation.parts.empty?
          legislation.sections.each { |section| create_act_section section }
        else
          legislation.parts.each { |part| create_act_part part if part }
        end
      end
    end
  end

  def opsi_search_url name
    "http://search.opsi.gov.uk/search?q=#{URI.escape(name)}&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection"
  end

  def search_opsi
    begin
      doc = Hpricot.XML open(opsi_search_url(name))
    rescue Exception => e
      warn e.class.name
      warn 'error retrieving: ' + opsi_search_url(name)
      warn e.to_s
      warn e.backtrace.join("\n")
    end
  end

  def populate_legislation_urls_via_opsi
    if doc = search_opsi
      url = nil
      (doc/'R/T').each do |result|
        unless url
          term = result.inner_text.gsub(/<[^>]+>/,'').strip
          title_re = title.gsub('(','\(').gsub(')','\)')
          url = result.at('../U/text()').to_s if(name == term || term[/^#{title_re}/i] )
        end
      end

      if url
        self.opsi_url = url
        if opsi_url[/ukpga/]
          self.legislation_url = "http://www.legislation.gov.uk/ukpga/#{year}/#{number}"
        end
        populate_act_sections_from_opsi_url
      else
        warn "cannot find an opsi url for '#{name}' / '#{title}': #{opsi_search_url(name)}"
      end
    end
  end

  def populate_act_sections_from_opsi_url
    if act_sections.size == 0 && opsi_url && legislation_url
      doc = Hpricot open(opsi_url)
      (doc/'span[@class="LegDS LegContentsNo"]').each do |span|
        section_number = span.inner_text.chomp('.')
        if span.at('a')
          path = span.at('a')['href']
          base = opsi_url[/^(.+\/)[^\/]+$/,1]
          section_title = span.next_sibling.inner_text

          act_sections.build :section_number => section_number, :title => section_title,
              :opsi_url => "#{base}#{path}",
              :legislation_url => "#{legislation_url}/section/#{section_number}"
        else
          warn "cannot find opsi url for section #{section_number} of #{name}"
        end
      end
    end
  end
end
