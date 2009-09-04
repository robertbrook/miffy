require 'mechanize'

class Bill < ActiveRecord::Base

  has_many :mif_files
  has_many :note_by_clauses
  has_many :note_by_schedules

  validates_presence_of :name
  before_validation :populate_parliament_url
  after_find :populate_parliament_url

  class << self
    def from_name name
      find_or_create_by_name(name)
    end
  end

  def clauses_file
    files = mif_files.select{|x| x.name[/clauses\./i]}
    if files.size == 1
      files.first
    elsif files.size > 1
      raise "can't find single matching clauses file"
    else
      nil
    end
  end

  protected
    def populate_parliament_url
      unless parliament_url
        search_url = "http://www.publications.parliament.uk/cgi-bin/search.pl?q=%22#{URI.escape(name)}%22+more%3Abusiness"
        links = nil

        begin

          WWW::Mechanize.new.get(search_url) do |result|
            links = result.links.select {|x| x.text[name] && x.uri.to_s['services'] }
          end

          self.parliament_url = if links && links.size == 1
            links.first.uri.to_s
          else
            nil
          end
        rescue Exception => e
          logger.warn "cannot connect to: #{search_url}"
          nil
        end
      end
    end
end
