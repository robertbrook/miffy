require 'regexp_generator'

class ExternalReferenceResolver

  attr_accessor  :text, :scanner

  OPTIONAL_COMMA = '(?:,(?!(?:\sAND|\sand)?\s(?:THE|the)))?' # optional comma, but not ', the' or ', and the'

  TITLE_CASE_WORD = /(?:[A-Z][a-z\-]+ # titlecase letter followed by at least one lower case letter, or hyphen
    #{OPTIONAL_COMMA}
    '?[s]?                            # optional apostrophe and s
    )
    /x

  CAPS_WORD = /(?:[A-Z]+              # at least one capital letter
    #{OPTIONAL_COMMA}                 # not followed by the word UNDER
    '?S?                              # optional apostrophe and s
    (?!\sUNDER\s))
    /x

  CONJUNCTION_IN_MATCH = /and(?!\s(of\s|in\s)?the)|for|of|by(?!\sthe)|to|in|the|into(?!\sthe)|other|etc\.|&C\./i

  def initialize(text)
    self.text = text
    self.scanner = StringScanner.new(text)
  end

  def screening_pattern
    nil
  end

  def positive_pattern_groups
    []
  end

  def positive_patterns
    positive_pattern_groups.map{ |pattern, group| pattern }
  end

  def negative_patterns
    []
  end

  def any_positive_pattern
    Regexp.union( *positive_patterns )
  end

  def reference_replacement(reference)
    reference
  end

  def any_references?
    if screening_pattern
      return false unless self.scanner.exist?(screening_pattern)
    end

    positive_patterns.each do |pattern|
      return true if self.scanner.exist?(pattern)
    end
    false
  end

  def each_reference
    return unless any_references?
    loop do
      found = self.scanner.scan_until(any_positive_pattern)
      break if not found
      reference = self.scanner.matched

      unless match_patterns(negative_patterns, reference)
        if (reference_data = get_match reference)
          yield reference_data
        end
      end
    end
    self.scanner.reset
  end

  def references
    refs = []
    each_reference do |reference, start_position, end_position|
      refs << reference
    end
    refs
  end

  def markup_references
    marked_up = ''
    last_position = 0
    each_reference do |reference, start_position, end_position|
      marked_up += self.text[last_position...start_position]
      last_position = end_position
      if block_given?
        marked_up += yield(reference)
      else
        marked_up += reference_replacement(reference)
      end

    end
    marked_up += self.text[last_position...self.text.size]
  end

  protected

    def get_match reference
      positive_pattern_groups.each do |pattern, group|
        if (match = pattern.match(reference))
          start_position = self.scanner.pos - self.scanner.matched_size
          return [match[group], start_position + match.begin(group), start_position + match.end(group)]
        end
      end
      nil
    end

    def match_patterns(pattern_list, text)
      pattern_list.each do |pattern|
        return true if pattern.match(text)
      end
      return false
    end

end