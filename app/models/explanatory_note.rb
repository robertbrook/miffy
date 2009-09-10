class ExplanatoryNote < ActiveRecord::Base

  belongs_to :explanatory_notes_file
  belongs_to :bill

  validates_presence_of :note_text

  def html_note_text
    tokens = note_text.gsub("\r","").gsub(/\n\s+\n/,"\n\n").split("\n\n")

    html = tokens.collect do |token|
      lines = token.split("\n")
      result = []

      if lines.first[/^\s*Clause (\d+|\d+:.+)\s*$/]
        result << '<span class="NoteClauseTitle">Clause ' + $1 + '</span>'
        make_paragraph result, lines, adj=1
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

      if (lines.size-adj) == 1
        html << "<p>#{first_line}</p>"
      else
        html << "<p>#{first_line}"
        if lines.size > 2+adj
          rest = lines[(1+adj)..(lines.size-2)]
          rest.each {|line| html << line.strip}
        end
        html << "#{lines.last.strip}</p>"
      end
    end

end
