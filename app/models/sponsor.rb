class Sponsor < ActiveRecord::Base
  
  has_and_belongs_to_many :amendments
  
end