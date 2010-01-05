# require 'rubygems'
# require 'fastercsv'
# "./effects/Digital Economy Bill Table of Effects.csv"

class Effect < ActiveRecord::Base

  belongs_to :bill
  
  # def load_from_csv_file path, bill_name
  #    
  #    FasterCSV.foreach(path, {:headers => true}) do |row|
  #       Effect.create( :field => 'value', :other_field => 42 )
  #       
  #       :bill_id
  #       :affected_legislation
  #       :affected_provision
  #       :type_of_effect
  #       :affecting_legislation
  #       :affecting_provision
  #    end
  #    
  #  end
  
end
