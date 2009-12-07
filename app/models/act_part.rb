class ActPart < ActiveRecord::Base

  belongs_to :act
  has_many :act_sections

end
