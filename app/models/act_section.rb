class ActSection < ActiveRecord::Base

  belongs_to :act
  belongs_to :act_part

  def label
    "Section #{section_number}: #{title}"
  end

  def legislation_uri_for_subsection subsection_number
    "#{legislation_url}/#{subsection_number}"
  end
end
