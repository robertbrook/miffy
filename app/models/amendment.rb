class Amendment < ActiveRecord::Base
  
  belongs_to :bill
  has_and_belongs_to_many :sponsors
  
end