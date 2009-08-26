require 'hpricot'

class ExplanatoryNotesFile < ActiveRecord::Base

  belongs_to :bill

  has_many :explanatory_notes

  validates_presence_of :name, :path
  validates_uniqueness_of :path

  before_validation_on_create :set_name, :set_bill, :load_notes

  class << self
    def load paths
      paths.each do |file_path|
        find_or_create_by_path file_path
      end
    end
  end

  def load_notes
    xml = ExplanatoryNotesParser.parse(path)
    clauses = get_clauses(xml)

    clauses.each do |data|
      self.<< NoteByClause.new(:clause_number => data[0], :note_text => data[1])
    end
  end

  def get_clauses xml
    doc = Hpricot.XML(xml)
    clauses = (doc/'Clause')
    clauses.collect do |node|
      [node['Number'], node.inner_text]
    end
  end

  private
    def set_name
      self.name = File.basename(path, ".pdf") if path
    end

end
