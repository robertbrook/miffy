# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def document_type file_name
    if file_name.include?('Clauses.mif') || file_name.include?('Clauses.xml')
      "clauses"
    elsif file_name.include?('Cover.mif')
      "cover"
    elsif file_name.include?('Arrangement.mif')
      "arrangement"
    elsif (file_name =~ /pbc(.)*m.mif/).is_a?(Fixnum)
      "amendment_paper"
    elsif (file_name =~ /pbc(.)*a.mif/).is_a?(Fixnum) || file_name.include?('CommA')
      "marshalled_list"
    elsif file_name.include?('2.mif') || file_name.include?('Report.mif') || file_name.include?('amsorig.mif')
      "consideration"
    else
      "converted"
    end
  end

end
