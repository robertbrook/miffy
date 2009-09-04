require 'hpricot'

class ExplanatoryNotesFile < ActiveRecord::Base

  belongs_to :bill

  has_many :explanatory_notes

  validates_presence_of :name, :path
  validates_uniqueness_of :path

  before_validation_on_create :set_name, :set_bill
  after_create :load_notes

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
      NoteByClause.create!(:clause_number => data[0], :note_text => data[1], :bill_id => self.bill_id, :explanatory_notes_file_id => self.id)
    end
    
    schedules = get_schedules(xml)
    schedules.each do |data|
      NoteBySchedule.create!(:schedule_number => data[0], :note_text => data[1], :bill_id => self.bill_id, :explanatory_notes_file_id => self.id)
    end
  end

  def get_clauses xml
    doc = Hpricot.XML(xml)
    clauses = (doc/'Clause')
    clauses.collect do |node|
      [node['Number'], node.inner_text]
    end
  end
  
  def get_schedules xml
    doc = Hpricot.XML(xml)
    clauses = (doc/'Schedule')
    clauses.collect do |node|
      [node['Number'], node.inner_text]
    end
  end
  
  def get_bill_name xml
    doc = Hpricot.XML(xml)
    (doc/'BillInfo/Title').inner_text
  end
  
  def get_bill_id bill_name
    bill = Bill.find_by_name(bill_name)
    if bill.nil?
      nil
    else
      bill.id
    end
  end

  private
    def set_name
      self.name = File.basename(path, ".pdf") if path
    end
    
    def set_bill
      xml = ExplanatoryNotesParser.parse(path)
      bill_name = get_bill_name(xml)
      bill = Bill.find_by_name(bill_name)
      unless bill.nil?
        self.bill_id = bill.id
      end
    end
end
