class Act < ActiveRecord::Base
  
  validates_presence_of :name
  before_validation :populate_opsi_url

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
  
  private
  
    def populate_opsi_url
      unless opsi_url
        search_url = "http://search.opsi.gov.uk/search?q=#{URI.escape(name)}&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection"
        begin
          doc = Hpricot.XML open(search_url)
          url = nil
          
          (doc/'R/T').each do |result|
            term = result.inner_text.gsub(/<[^>]+>/,'')          
            url = result.at('../U/text()').to_s if name == term
          end
          
          self.opsi_url = url
        rescue Exception => e
          puts 'error retrieving: ' + search_url
          puts e.class.name
          puts e.to_s
        end
      end
    end
end
