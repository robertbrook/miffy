# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def external_sheet
    params[:style]
  end
  
  def target_file
    params[:file] || "Index"    
  end
  
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
      when 'Schedules'
        "schedules"
      when 'Arrangement'
        "arrangement"
      when 'Amendments'
        "amendment_paper"
      when 'Tabled Amendments'
        "tabled_amendments"
      when 'Marshalled List'
        "marshalled_list"
      when 'Report'
        "report"
      when 'Tabled Report'
        "report"
      else
        if file_name =~ /Finance_Clauses.xml$/
          "clauses"
        else
          "converted"
        end
    end
  end
  
  def stylesheet_path file_name, ens=''
    mif_file = MifFile.find_by_path(file_name)

    case mif_file.file_type
      when 'Clauses'
        if ens == 'interleaved'
          "clauses/clauses_interleaved"
        elsif ens == 'interleaved_wide'
          "clauses/clauses_interleaved_wide"
        else
          "clauses/clauses"
        end
      when 'Schedules'
        if ens == 'interleaved'
          "schedules/schedules_interleaved"
        elsif ens == 'interleaved_wide'
          "schedules/schedules_interleaved_wide"
        else
          "schedules/schedules"
        end
      when 'Arrangement'
        "arrangement/arrangement"
      when 'Amendments'
        "amendment_paper/amendment_paper"
      when 'Tabled Amendments'
        "amendment_paper/tabled_amendments"
      when 'Marshalled List'
        "amendment_paper/marshalled_list"
      when 'Report'
        "report/report"
      when 'Tabled Report'
        "report/report"
      else
        if file_name =~ /Finance_Clauses.xml$/
          "clauses/clauses"
        else
          "converted"
        end
    end
  end

end
