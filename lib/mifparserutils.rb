module MifParserUtils

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