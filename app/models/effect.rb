# require 'rubygems'
require 'fastercsv'
# "./effects/Digital Economy Bill Table of Effects.csv"

class Effect < ActiveRecord::Base

  belongs_to :bill
  validates_presence_of :bill_id
  
  class << self
    def load_from_csv_file path
      
      first_line = File.open("#{path}").readline
      parts = first_line.split(',')
      if !(parts[0].strip == "Date" &&
         parts[1].strip == "Affected Legislation (Act)" &&
         parts[2].strip == "Affected Provision" &&
         parts[3].strip == "Type of Effect" &&
         parts[4].strip == "Affecting Legislation (Year and Chapter or Number)" &&
         parts[5].strip == "Affecting Provision" &&
         parts[6].strip == "Amendment applied to Database" &&
         parts[7].strip == "Checked (Y or leave Blank)" &&
         parts[8].strip == "Transferred to Final TOES Chart (Date)")
        raise "error: unexpected csv header format for effects"
      end
      
      FasterCSV.foreach("#{path}", {:headers => true}) do |row|
        bill = Bill.find_by_name(row["Affecting Legislation (Year and Chapter or Number)"])
        if bill
          Effect.create(
            :bill_id => bill.id,
            :affected_legislation => row["Affected Legislation (Act)"],
            :affected_provision => row["Affected Provision"],
            :type_of_effect => row["Type of Effect"],
            :affecting_provision => row["Affecting Provision "]
          )
        end
      end    
    end
  end
  
end
