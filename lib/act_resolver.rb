class ActResolver < ExternalReferenceResolver

  NUMBER = 'No\.\s\d+'
  ARTICLE = 'The|This|An|That'

  PREFIXES = /(?:            # a non-stored group made up of one of
                \A(?:Draft\s)? # the start of the string
                |
                (?:Under\s)? # optional text Under
                the\s        # then the
                (?:Draft\s)?
                |
                Amendments?\sof\s
                |
                >\s*         # the end of a tag and optional space
                |
                \d+\.\s+     # number and a fullstop, optional space
                |
                \(           # an opening bracket
                |
                "            # a quote
                |
                &\#x2014;\s? # a dash
              )/ix           # case insensitive

  NEGATIVE_STARTS = /(?!           # negative match - cant have any of the following at this point...
                      Act.?\s      # Act Acts or Act,
                      |
                      ^[^\(]*\)
                      |
                      Under\s      # Under
                      |
                      \w+,?\s+the    # one word then the, e.g. Although the
                      |
                      \w*\s+in\s+the    # word then in the, e.g. House in the, The House in the
                      |
                      !Representation\w*\sof\sthe
                      |
                      Commencement\s
                      |
                      If\s         # If
                      |
                      Again,?\s
                      |
                      Every\s
                      |
                      Exceptions\s
                      |
                      Exclusion\sof\s
                      |
                      Experience\sof
                      |
                      Certainly,?\s
                      |
                      \w*\s*Part\s\w+\sof\sthe\s
                      |
                      \w+\sOrder\sin\sthe\s
                      |
                      General\sDevelopment\sOrder\sof\sthe\s
                      |
                      \w+\s(?:R|B)eading # someword Reading
                      |
                      (?:\w|-)*\s*Clause # someword Clause
                      |
                      \w*(?:\sand\s\w+)?\s*Schedules? # someword Schedule
                      |
                      \w*\s*Sections? # someword Sections
                      |
                      Chapter\s\w+\sof\sPart
                      |
                      Changes\sto\sthe
                      |
                      Copies\sof\sthe
                      |
                      Committees?\sof\sthe
                      |
                      Division\sList\sfor\s
                      |
                      \w+,\s(?:in|for|to)\sthe
                      |
                      Explanatory\sMemorandum\sto
                      |
                      Extension\sof\s
                      |
                      Guide\s+to
                      |
                      Houses?\s(?:of|to)\sthe
                      |
                      However
                      |
                      (?:I|V|X){1,5}\s
                      |
                      In\s
                      |
                      According\sto
                      |
                      Addition\sto
                      |
                      Amendments?\sof
                      |
                      Amending\s
                      |
                      No\s
                      |
                      Of\s
                      |
                      On\s
                      |
                      Order\s(?:of|for|to|and\sDisposition)\s
                      |
                      Other\s
                      |
                      Our\s
                      |
                      Owing\sto\s
                      |
                      Parts?\s
                      |
                      Petitions?\s(?:from|for)\s
                      |
                      Possible\s
                      |
                      Prior\s
                      |
                      Provisi?ons?\s(?!Act)
                      |
                      Purposes\sof\s
                      |
                      Pursuant\sto\s
                      |
                      Repeal\sof\s
                      |
                      Review\sof\s
                      |
                      Revision\sof\s
                      |
                      Report\s(?:Stage\s)?(?:of|to)\sthe\s
                      |
                      Referring\sto\s
                      |
                      Regulations\sof\s
                      |
                      Secretary\sof\sState\s(?:in|for)\sthe\s
                      |
                      Second\s
                      |
                      See\s
                      |
                      Statute\sBook\s(?!Act)
                      |
                      Table\sof\sSeats\s
                      |
                      This\s
                      |
                      That\s
                      |
                      Thirdly
                      |
                      Title\sof\s
                      |
                      To\s
                      |
                      Vote\sto\s
                      |
                      Modifications?\sof\s
                      |
                      Minister\sto\s
                      |
                      Member\sfor\s
                      |
                      Moved,\s
                      |
                      Preamble\s
                      |
                      Because\s
                      |
                      Repeal\sof\s
                      |
                      (?:After|Before)\s
                      |
                      Amendments?\sto
                      |
                      Bill\sfor\s
                      |
                      Breaches\sof\s
                      |
                      Application\sof\s
                      |
                      Enforcement\sof\s
                      |
                      Administration\sof\sthe
                      |
                      Adjusted\sfor\sthe
                      |
                      Yes            # single non-Act word like Yes at the start of the reference
                      |
                      The\s          # discard a leading The
                      |
                      A(?:n,?|nd|ny)?\s   # discard a leading A An, An or And or Any
                      |
                      As\s(?:to|for)\s  # discard a leading As to or As for
                      |
                      Conservative  # Proper noun or sentence starting adjectives like Conservative
                      |
                      Labour
                      |
                      Liberal\sDemocrat
                      |
                      British\sParliament
                      |
                      United\sKingdom\s(?:to|the)\s
                      |
                      United\sStates\s(?:of\sAmerica\s)?(?:the|of)\s
                      |
                      Government's
                      |
                      Department's
                    )/ix

  ACT_PATTERN = /#{PREFIXES}                      # prefixes matched but not kept
                 #{NEGATIVE_STARTS}               # any of these means no match
                 (((#{TITLE_CASE_WORD}            # start of the Act - a titlecase word
                 |
                 #{CAPS_WORD})                    # or caps word
                 (\s|-))                          # space or hyphen
                 (                                # then
                   (\((?=.*\)))?                  # optional open bracket (that has to be closed somewhere)
                     (#{TITLE_CASE_WORD}           # titlecase word
                       |
                      #{CAPS_WORD}
                       |                          # or
                       (#{CONJUNCTION_IN_MATCH})  # conjunction
                       |                          # or
                       #{NUMBER}                  # number
                      )
                   \)?                            # optional close bracket
                   (\s|-)                         # and space or hyphen
                  )*?                             # zero or more times - non-greedy
                  (Act|ACT)                       # then the word Act
                  (?![A-Za-z])                    # not followed by a letter, for example s
                  (,?\s\d\d\d\d)?)                 # then an optional year, preceded by an optional comma
                  /x

  NEGATIVE_ACT_PATTERN = /
      ((#{ARTICLE})\sAct
        |
        \s(#{CONJUNCTION_IN_MATCH})\sAct
        |
        Notes\sfor\s
        |
        Before\sAct
        |
        British\sAct
        |
        Canada's\sAct
        |
        Earlier\sAct
        |
        Prior\sAct
        |
        Acts\sand\s
        |
        Your\sAct
        |
        Which\sAct
        |
        Petitions?\sof\s(?!Right)
        |
        ^\(.*\)
        |
        ^My\s
        |
        (#{CONJUNCTION_IN_MATCH})\sFinal\sAct
        |
        Double-Act
        |
        ,\sAct$
        |
        \-Act$
        |
        (^(the\s)?English\sAct
      ))
      /xi

  def screening_pattern
    /(Act|ACT)(?![A-Za-z])/
  end

  def positive_pattern_groups
    [[ACT_PATTERN, 1]]
  end

  def negative_patterns
    [NEGATIVE_ACT_PATTERN]
  end

  YEAR = regexp '\d\d\d\d'

  def name_and_year(act_reference)
    if (year_match = YEAR.match(act_reference))
      osub!(act_reference, YEAR, '')
      act_reference.strip!
      act_reference.chomp!(',')
      year_match = year_match[0]
    end
    [act_reference, year_match]
  end

  def mention_attributes
    act_mentions = []
    each_reference do |reference, start_position, end_position|
      name, year = name_and_year(reference)
      act_mentions << {:name => name,
                       :year => year,
                       :start_position => start_position,
                       :end_position => end_position}
    end
    act_mentions
  end

end