# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def document_type file_name, ens=''
    mif_file = MifFile.find_by_path(file_name)

    case mif_file.file_type
      when 'Clauses'
        if ens == 'interleaved'
          "clauses_interleaved"
        elsif ens == 'interleaved_wide'
          "clauses_interleaved_wide"
        else
          "clauses"
        end
      when 'Arrangement'
        "arrangement"
      when 'Amendments'
        "amendment_paper"
      when 'Marshalled List'
        "marshalled_list"
      when 'Report'
        "consideration"
      when 'Tabled Report'
        "consideration"
      else
        if file_name =~ /Finance_Clauses.xml$/
          "clauses"
        else
          "converted"
        end
    end
  end

end
