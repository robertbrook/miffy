class ExplanatoryNote < ActiveRecord::Base

  belongs_to :explanatory_notes_file
  belongs_to :bill

  validates_presence_of :note_text

  def html_note_text
    @in_list = false
    tokens = note_text.gsub("\r","").gsub(/\n\s+\n/,"\n\n").split("\n\n")

    html = tokens.collect do |token|
      lines = token.split("\n")
      result = []

      if lines.first[/^\s*Clause (\d+|\d+:.+)\s*$/]
        result << '<span class="NoteClauseTitle">Clause ' + $1 + '</span>'
        make_paragraph result, lines, adj=1
      elsif lines.size > 1 && lines[1][/^\s*Clause (\d+|\d+:.+)\s*$/]
        result = result << '<span class="NoteClauseTitle">Clause ' + lines[0] + '<br />' + lines[1] + '</span>'
        make_paragraph result, lines, adj=2
      elsif lines.first[/^\s*Schedule (\d+|\d+:.+)\s*$/]
        result << '<span class="NoteScheduleTitle">Schedule ' + $1 + '</span>'
        make_paragraph result, lines, adj=1
      elsif lines.size > 1 && lines[1][/^\s*Schedule (\d+|\d+:.+)\s*$/]
        result = result << '<span class="NoteScheduleTitle">Schedule ' + lines[0] + '<br />' + lines[1] + '</span>'
        make_paragraph result, lines, adj=2
      else
        make_paragraph result, lines
      end

      result.join(' ')
    end

    html.join('')
  end

  private

    def make_paragraph html, lines, adj=0
      first_line = lines[0+adj].strip
      list_item = false

      if first_line[/• /]
        first_line = first_line.gsub("• ", "<li>") + "</li>"
        list_item = true
      end

      if (lines.size-adj) == 1
        if list_item
          unless @in_list
            html << "<ul>"
            @in_list = true
          end
          html << first_line
        else
          if @in_list && first_line.strip != ""
            html << "</ul>"
            @in_list = false
          end
          html << "<p>#{first_line}</p>"
        end
      else
        if list_item
          unless @in_list
            html << "<ul>"
            @in_list = true
          end
          html << first_line
        else
          if @in_list
            html << "</ul>"
            @in_list = false
          end
          html << "<p>#{first_line}"
        end
        if lines.size > 2+adj
          rest = lines[(1+adj)..(lines.size-2)]
          rest.each {|line| html << line.strip}
        end
        if list_item
          html << "#{lines.last.strip}</li>"
        else
          html << "#{lines.last.strip}</p>"
        end
      end
    end

end
