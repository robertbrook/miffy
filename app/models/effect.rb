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
          reference_to_bill = row["Affecting Provision "]
          response = parse_bill_provision_reference(reference_to_bill)
          reference_parsed = response[1]
          html_ref = response[0]
          
          unless html_ref
            warn "unable to handle reference to bill: #{reference_to_bill} in effects file" unless RAILS_ENV == 'test'
          end
          
          while !reference_to_bill.blank? && html_ref
            Effect.create(
              :bill_id => bill.id,
              :bill_provision => html_ref,
              :affected_act => row["Affected Legislation (Act)"],
              :affected_act_provision => row["Affected Provision"],
              :type_of_effect => row["Type of Effect"]
            )
            reference_to_bill.gsub!(reference_parsed, '').strip
            unless reference_to_bill.blank?
              response = parse_bill_provision_reference(reference_to_bill)
              reference_parsed = response[1]
              html_ref = response[0]
            end
          end
        end
      end    
    end
    
    def parse_bill_provision_reference reference
      parsed_ref = nil
      found_ref = ""
      
      if reference =~ /(^s. 0*(\d+)(?:\(0*(\d+)\))?(?:\((\w+)\))?)/
        parsed_ref = "clause#{$2}"
        parsed_ref += "-#{$3}" if $3
        parsed_ref += "-#{$4}" if $4
        found_ref = $1
      elsif reference =~ /(Sch. 0*(\d)(?: para. 0*(\d+))?(?:\(0*(\d+)\))?(?:\(0*(\w+)\))?)/
        parsed_ref = "schedule#{$2}"
        parsed_ref += "-#{$3}" if $3
        parsed_ref += "-#{$4}" if $4
        parsed_ref += "-#{$5}" if $5
        found_ref = $1
      end
      [parsed_ref, found_ref]
    end
    
  end
  
end
