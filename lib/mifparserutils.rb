module MifParserUtils

  NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX  = Regexp.new('(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n(\s+)(\]?,)', Regexp::MULTILINE)
  NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX_2  = Regexp.new('(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n', Regexp::MULTILINE)

  COMPRESS_WHITESPACE = /(Letter|FrameData|Dropcap|SmallCaps|Bold|Italic|\w+_number|PgfNumString_\d|(clause_.+\})|(name.+\})|Abt\d)\n/
  COMPRESS_WHITESPACE_2 = /(^\s*(#|%).+(PgfNumString|\w+_text|PageStart|Number|Page|Line|STText|Sponsor|AmendmentNumber_PgfTag|Given|Stageheader|Shorttitle))\n/
  COMPRESS_WHITESPACE_3 = /(^\s*(.BillTitle|%a.+\}))\n/

  TOGGLE_SHOW_REGEXP = Regexp.new('%span\.ClauseTitle_text<\n(\s+)([^\n]+)\n(\s+)\#(\d+)\.ClauseText', Regexp::MULTILINE)
  TOGGLE_SHOW_REGEXP_2 = Regexp.new('%span\.ClauseTitle_text<\n(\s+)([^\n]+)\n(\s+)\#(\d+en)\.ClauseTextWithExplanatoryNote', Regexp::MULTILINE)

  COMPRESS_WHITESPACE_4 = Regexp.new('(%a\{ :name => "[^"]+" \})<>\n(\s+#\d+)', Regexp::MULTILINE)

  COMPRESS_WHITESPACE_5 = Regexp.new('(“\n\s+)(%a\{[^\{]+\})<\n', Regexp::MULTILINE)

  AMEND_REF = Regexp.new('%a.AmendmentReference\{ :href => "([^"]+)" \}<')

  COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA  = Regexp.new('(\s+)(%a\{)([^\n]+)(\}\n)(\s+)([^\n]+)(\n)(\s+)(, )', Regexp::MULTILINE)
  COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_SEMICOLON = Regexp.new('(\s+)(%a\{)([^\n]+)(\}\n)(\s+)([^\n]+)(\n)(\s+)(;)', Regexp::MULTILINE)

  def format_haml haml, clauses_file_name=nil
    haml = haml.gsub(NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX,  '\1\2 <span class="\4_number">\6</span>\8')
    haml.gsub!(NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX_2,  '\1\2 <span class="\4_number">\6</span>' + "\n")

    matches = []
    haml.scan(COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA) do |match|
      matches << match
    end
    matches.each do |match|
      text = match.to_s
      to = "#{match[0]}=%Q{<a #{match[2].gsub(' => ','=').gsub(', :',' ').sub(' :',' ').strip}>#{match[5]}</a>,}\n#{match[7]}"
      haml.gsub!(text, to)
    end
    haml.scan(COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_SEMICOLON) do |match|
      matches << match
    end
    matches.each do |match|
      text = match.to_s
      to = "#{match[0]}=%Q{<a #{match[2].gsub(' => ','=').gsub(', :',' ').sub(' :',' ').strip}>#{match[5]}</a>;}\n#{match[7]}"
      haml.gsub!(text, to)
    end

    haml.gsub!(COMPRESS_WHITESPACE, '\1' + "<>\n")
    haml.gsub!(COMPRESS_WHITESPACE_2, '\1' + "<\n")
    haml.gsub!(COMPRESS_WHITESPACE_3, '\1' + "<\n")

    haml.gsub!(TOGGLE_SHOW_REGEXP, '%span.ClauseTitle_text<' + "\n" + '\1= link_to_function "\2", "$(\'\4\').toggle()"' + "\n" + '\3#\4.ClauseText')
    haml.gsub!(TOGGLE_SHOW_REGEXP_2, '%span.ClauseTitle_text<' + "\n" + '\1= link_to_function "\2", "$(\'\4\').toggle()"' + "\n" + '\3#\4.ClauseTextWithExplanatoryNote')

    haml.gsub!(COMPRESS_WHITESPACE_4, '\1' + "\n" + '\2')
    haml.gsub!(COMPRESS_WHITESPACE_5, '\1\2<>' + "\n" )

    if clauses_file_name
      link = '%a.AmendmentReference{ :href => "http://localhost:3000/convert?file=' + URI.encode(clauses_file_name) + '\1" }<'
      haml.gsub!(AMEND_REF, link)
    end
    haml.gsub!('\&nbsp; ','\ ')
    haml.gsub!(/(\s+)\\.\n/,'\1%span<>' + '\1  \.' + "\n")
    haml
  end

  def clean element
    element.at('text()').to_s[/`(.+)'/]
    text = $1
    if text
      text.gsub!('\xd4 ', '‘')
      text.gsub!('\xd5 ','’')
      text.gsub!('\xd2 ','“')
      text.gsub!('\xd3 ','”')
    else
      ''
    end
    text
  end

  def get_char element
    char = element.at('text()').to_s
    case char
      when 'NoHyphen'
        ''
      when 'SoftHyphen'
        '-'
      when 'EmSpace'
        ' '
      when 'Pound'
        '£'
      when 'EmDash'
        '—'
      when 'HardReturn'
        "/n"
      when 'HardSpace'
        " "
      when 'Tab'
        ' '
      else
        '[[' + char + ']]'
    end
  end
end