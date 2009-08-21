class ExplanatoryNotesFile < ActiveRecord::Base

  belongs_to :bill

  has_many :explanatory_notes

  validates_presence_of :name, :path
  validates_uniqueness_of :path

  before_validation_on_create :set_name, :load_notes

  class << self
    def load paths
      paths.each do |file_path|
        find_or_create_by_path file_path
      end
    end
  end

  def load_notes
    xml = ExplanatoryNotesParser.parse(path)
  end

  private
    def set_name
      self.name = File.basename(path, ".pdf") if path
    end

end
