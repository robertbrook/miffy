class ActSection < ActiveRecord::Base

  belongs_to :act
  belongs_to :act_part

  def label
    "Section #{number}: #{title}"
  end
end
