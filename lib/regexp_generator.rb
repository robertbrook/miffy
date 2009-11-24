def regexp pattern, option=nil, encoding='utf8'
  if Miffy::use_oniguruma
    Oniguruma::ORegexp.new(pattern, option, encoding)
  else
    if option
      if option == 'i'
        /#{pattern}/i
      else
        raise 'regexp option is un-handled: ' + option
      end
    else
      /#{pattern}/
    end
  end
end

def line_regexp_i pattern
  regexp('\A' + pattern + '\Z', 'i')
end

def ogsub! text, regexp, replacement
  if Miffy::use_oniguruma
    regexp.gsub!(text, replacement)
  else
    text.gsub!(regexp, replacement)
  end
end

def ogsub text, regexp, replacement
  if Miffy::use_oniguruma
    regexp.gsub(text, replacement)
  else
    text.gsub(regexp, replacement)
  end
end

def osub! text, regexp, replacement
  if Miffy::use_oniguruma
    regexp.sub!(text, replacement)
  else
    text.sub!(regexp, replacement)
  end
end