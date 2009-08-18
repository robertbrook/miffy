require 'mechanize'

class Bill < ActiveRecord::Base

  has_many :mif_files
  
  validates_presence_of :name
  before_validation :populate_parliament_url

  class << self
    def from_name name
      if bill = find_by_name(name)
        bill.populate_parliament_url unless bill.parliament_url?
        bill
      else
        create! :name => name
      end
    end
  end
  
  private
    def populate_parliament_url
      unless parliament_url
        search_url = "http://www.publications.parliament.uk/cgi-bin/search.pl?q=%22#{URI.escape(name)}%22+more%3Abusiness"
        links = nil
        
        WWW::Mechanize.new.get(search_url) do |result|
          links = result.links.select {|x| x.text[name] && x.uri.to_s['services'] }
        end
  
        self.parliament_url = if links && links.size == 1
          links.first.uri.to_s
        else
          nil
        end
      end
    end
end
