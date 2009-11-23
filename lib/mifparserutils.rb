module MifParserUtils

  NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX  = Regexp.new('(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n(\s+)(\]?,)', Regexp::MULTILINE)
  NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX_2  = Regexp.new('(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n', Regexp::MULTILINE)

  NEED_SPACE_BETWEEN_LABEL_AND_XREF_REGEX  = Regexp.new('(\s+)(\S+)\n(\s+)%span#(\S+)\.Xref\n(\s+)(\S+)\n(\s+)(\]?\)|,)(.+)', Regexp::MULTILINE)
  NEED_SPACE_BETWEEN_LABEL_AND_XREF_REGEX_2  = Regexp.new('(\s+)(\S+)\n(\s+)%span#(\S+)\.Xref\n(\s+)(\S+)\n(\s+)(\]?\)|,)', Regexp::MULTILINE)

  COMPRESS_WHITESPACE = /(Letter|FrameData|Dropcap|SmallCaps|Bold|Italic|\w+_number|PgfNumString_\d|(clause_.+\})|(name.+\})|Abt\d)\n/
  COMPRESS_WHITESPACE_2 = /(^\s*(#|%).+(PgfNumString|\w+_text|PageStart|Number|Xref|Page|Line|STText|Sponsor|AmendmentNumber_PgfTag|Given|Stageheader|Shorttitle))\n/
  COMPRESS_WHITESPACE_3 = /(^\s*(.BillTitle|%a.+\}))\n/

  TOGGLE_SHOW_REGEXP = Regexp.new('(\s+)%span\.ClauseTitle_text<\n(\s+)([^\n]+)\n(\s+)\#(\d+)\.ClauseText', Regexp::MULTILINE)
  TOGGLE_SHOW_REGEXP_2 = Regexp.new('(\s+)%span\.ClauseTitle_text<\n(\s+)([^\n]+)\n(\s+)\#(\d+en)\.ClauseTextWithExplanatoryNote', Regexp::MULTILINE)

  COMPRESS_WHITESPACE_4 = Regexp.new('(%a\{ :name => "[^"]+" \})<>\n(\s+#\d+)', Regexp::MULTILINE)

  COMPRESS_WHITESPACE_5 = Regexp.new('(“\n\s+)(%a\{[^\{]+\})<\n', Regexp::MULTILINE)

  AMEND_REF = Regexp.new('%a.AmendmentReference\{ :href => "([^"]+)" \}<')

  COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA  = Regexp.new('(\s+)(%a\{)([^\n]+)(\}\n)(\s+)([^\n]+)(\n)(\s+)(, )', Regexp::MULTILINE)
  COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA_2  = Regexp.new('((\s+)(%a\#([^\n]+)\.Citation\{)([^\n]+)(\}\n)(\s+)([^\n]+)(\n)(\s+)(, ?))', Regexp::MULTILINE)
  COLLAPSE_SPACE_BETWEEN_SPAN_AND_COMMA  = Regexp.new('((\s+)(%span\.Citation\n)(\s+)([^\n]+)(\n)(\s+)(, ?))', Regexp::MULTILINE)
  COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_SEMICOLON = Regexp.new('(\s+)(%a\{)([^\n]+)(\}\n)(\s+)([^\n]+)(\n)(\s+)(;)', Regexp::MULTILINE)

  def format_haml haml, clauses_file_name=nil
    haml = haml.gsub(NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX,  '\1\2 <span class="\4_number">\6</span>\8')
    haml.gsub!(NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX_2,  '\1\2 <span class="\4_number">\6</span>' + "\n")
    haml.gsub!(NEED_SPACE_BETWEEN_LABEL_AND_XREF_REGEX, '\1\2 <span class="Xref" id="\4">\6</span>\8\9')
    haml.gsub!(NEED_SPACE_BETWEEN_LABEL_AND_XREF_REGEX_2, '\1\2 <span class="Xref" id="\4">\6</span>\8')

    matches = []
    haml.scan(COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA) do |match|
      matches << match
    end
    matches.each do |match|
      text = match.to_s
      to = "#{match[0]}=%Q{<a #{match[2].gsub(' => ','=').gsub(', :',' ').sub(' :',' ').strip}>#{match[5]}</a>,}\n#{match[7]}"
      haml.gsub!(text, to)
    end

    matches.clear
    haml.scan(COLLAPSE_SPACE_BETWEEN_ANCHOR_AND_COMMA_2) do |match|
      matches << match
    end
    matches.each do |match|
      text = match[0].to_s
      to = %Q|#{match[1]}=%Q{<a id="#{match[3]}" class="Citation" #{match[4].gsub(' => ','=').gsub(', :',' ').sub(' :',' ').strip}>#{match[7]}</a>,}\n#{match[9]}|
      haml.gsub!(text, to)
    end
    matches.clear
    haml.scan(COLLAPSE_SPACE_BETWEEN_SPAN_AND_COMMA) do |match|
      matches << match
    end
    matches.each do |match|
      text = match[0].to_s
      to = %Q|#{match[1]}=%Q{<span class="Citation">#{match[4]}</span>,}\n#{match[6]}|
      haml.gsub!(text, to)
    end

    matches.clear
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

    haml.gsub!(TOGGLE_SHOW_REGEXP,   '\1= link_to_function \'<img alt="" id="\5_img" src="/images/down-arrow.png">\', "$(\'\5\').toggle();imgswap(\'\5_img\')"' + "" + '\1%span.ClauseTitle_text<' + "\n" + '\2= link_to_function "\3", "$(\'\5\').toggle();imgswap(\'\5_img\')"' + "\n" + '\4#\5.ClauseText')
    haml.gsub!(TOGGLE_SHOW_REGEXP_2, '\1= link_to_function \'<img alt="" id="\5_img" src="/images/down-arrow.png">\', "$(\'\5\').toggle();imgswap(\'\5_img\')"' + "" + '\1%span.ClauseTitle_text<' + "\n" + '\2= link_to_function "\3", "$(\'\5\').toggle();imgswap(\'\5_img\')"' + "\n" + '\4#\5.ClauseTextWithExplanatoryNote')

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
      text.gsub!('&amp;','&')
      text.gsub!('&','&amp;')
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

  def start_tag tag, element
    attributes = get_attributes(element)
    tag = %Q|<#{tag} id="#{get_uid(element)}"#{attributes}>|
    if @suffix
      tag += @suffix.to_s
      @suffix = nil
    end
    tag
  end

  def get_attributes element, includes=nil
    element = (element/'Attributes') if @e_tag == 'Clauses.ar'
    attributes = (element/'../Attributes/Attribute')
    attribute_list = ''
    if attributes && attributes.size > 0
      attributes.each do |attribute|
        name = clean(attribute.at('AttrName'))
        if name[/\.(.+)/]
          name = $1
        end
        value = clean(attribute.at('AttrValue'))
        if includes.blank? || includes.include?(name)
          attribute_list += %Q| #{name}="#{value}"|
        end
      end
    end
    attribute_list
  end

  def get_uid element
    element.at('../Unique/text()').to_s
  end

end