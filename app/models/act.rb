require 'open-uri'
require 'morph'
require 'hpricot'
require 'legislation_uk'

class Act < ActiveRecord::Base

  has_many :act_parts, :dependent => :delete_all
  has_many :act_sections, :dependent => :delete_all

  validates_presence_of :name, :legislation_url
  validates_uniqueness_of :legislation_url

  before_validation :populate_year, :populate_number, :populate_title,
      :populate_legislation_urls, :populate_act_sections

  class << self
    def from_name name
      if act = find_by_name(name)
        act
      else
        logger.info "creating from name: #{name}"
        create! :name => name
      end
    end
  end

  def find_section_by_number section_number
    act_sections.find_by_number section_number
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

  def get_legislation
    if @legislation
      @legislation
    elsif number?
      @legislation = Legislation::UK.find(title, number)
    else
      @legislation = Legislation::UK.find(title)
    end
  end

  def populate_legislation_urls
    if legislation_url.blank?
      if legislation = get_legislation
        self.legislation_url = legislation.legislation_uri
        self.opsi_url = legislation.opsi_uri
        self.statutelaw_url = legislation.statutelaw_uri
      end
    end
  end

  def populate_act_sections
    if act_sections.empty?
      if legislation = get_legislation
        legislation.parts.each do |part|
          act_part = act_parts.build :name => part.number,
              :title => part.title,
              :legislation_url => part.legislation_uri

          part.sections.each do |section|
            act_sections.build :number => section.number,
                :title => section.title,
                :act_part => act_part,
                :legislation_url => section.legislation_uri
          end
        end
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

          act_sections.create :number => section_number, :title => section_title,
              :opsi_url => "#{base}#{path}",
              :legislation_url => "#{legislation_url}/#{section_number}"
        else
          warn "cannot find opsi url for section #{section_number} of #{name}"
        end
      end
    end
  end
end
