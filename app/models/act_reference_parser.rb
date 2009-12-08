require 'rubygems'
require 'hpricot'

class ActReferenceParser

  class << self

    def internal_id_part node
      part = nil
      case node.name
        when 'Amendment'
          part = "amendment"
        when 'SubSection'
          if (num = node.at('SubSection_PgfTag/PgfNumString'))
            part = "subsection#{num.inner_text.tr('()','').strip}"
          end
        when 'Clause'
          if (num = node.at('ClauseTitle/ClauseTitle_PgfTag/PgfNumString') )
            part = "clause#{num.inner_text.tr('()','').strip}"
          end
        when 'Para'
          if (num = node.at('Paragraph_PgfTag/PgfNumString') )
            part = "#{num.inner_text.tr('()','').strip}"
          end
      end
      part
    end

    def internal_ids doc
      ids = {}
      (doc/'//[@Id]').each do |e|

        if e['Number']
          id = "#{e.name.to_s.downcase}#{e['Number']}#{e['Letter'] ? e['Letter'] : ''}"
        elsif part = internal_id_part(e)
          id = part
        end

        parent = e.parent
        while parent
          if part = internal_id_part(parent)
            id = "#{part}-#{id}"
          end
          parent = parent.parent
        end

        ids[e['Id']] = id
      end
      ids
    end

    def handle_internal_ids doc
      internal_ids = internal_ids(doc)
      internal_ids.each do |id, anchor_name|
        element = doc.at("//[@Id = '#{id}']")
        element.set_attribute('anchor', anchor_name)
      end
    end
  end

  def parse_xml_file xml_file, options={}
    parse_xml(IO.read(xml_file), options)
  end

  def attributes resource, href, title
    if title
      %Q|rel="cite" resource="#{resource}" href="#{href}" title="#{title}"|
    else
      %Q|rel="cite" resource="#{resource}" href="#{href}"|
    end
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml

    act_abbreviations = (doc/'//Interpretation/ActAbbreviation')
    clauses = (doc/'ClauseText')
    handle_abbreviated_act_references(act_abbreviations, clauses) unless act_abbreviations.empty?

    act_citations = (doc/'//Clause/ClauseText//Citation')
    handle_act_citation_references(act_citations) unless act_citations.empty?

    clauses = (doc/'ClauseText') + (doc/'LongTitle')
    mentions = clauses.collect {|clause| handle_raw_act_mentions(clause) }.include?(true)

    ActReferenceParser.handle_internal_ids(doc)

    no_references = (act_abbreviations.empty? && act_citations.empty? && !mentions)
    no_references ? xml : doc.to_s
  end

  private

    def handle_raw_act_mentions clause
      mentions = false
      if clause.inner_html.include?('Act')
        text = clause.inner_html
        act_mentions = ActResolver.new(text).mention_attributes

        unless act_mentions.empty?
          [act_mentions.first].each do |mention|
            text = clause.inner_html
            preceding_text = text[0..(mention.start_position-1)]
            following_text = text[mention.end_position..text.length]

            if preceding_text[/title="$/]
              # ignore
            elsif following_text[/^\s?<(\/Citation|ParaLineStart)/]
              # ignore
            else
              name = "#{mention.name} #{mention.year}"
              act = Act.from_name name

              if act
                if mention.section_number && (section = act.find_section_by_number(mention.section_number))
                  url = section.statutelaw_url ? section.statutelaw_url : section.opsi_url
                else
                  url = act.statutelaw_url ? act.statutelaw_url : act.opsi_url
                end

                if url
                  link = %Q|<a href="#{url}" rel="cite">#{mention.text}</a>|
                  new_text = "#{preceding_text}#{link}#{following_text}"
                  clause.inner_html = new_text
                  mentions = true
                end

              end
            end
          end
        end
      end
      mentions
    end

    def handle_act_citation_references act_citations
      act_citations.each do |citation|
        reference, number = find_section_preceeding citation
        if reference
          act_title = citation.inner_text
          act = Act.find_by_name(act_title)
          if act
            clause = citation.parent
            add_link(clause, "#{reference} #{citation.to_s}") { %Q|<a #{section_cite_attributes(act, number, [])}>#{reference} #{citation.inner_html}</a>| }
          else
            warn "can't find act: #{act_title}"
          end
        end
      end
    end

    def add_link clause, old_html
      html = clause.inner_html
      changed = html.gsub(old_html, yield )
      clause.inner_html = changed
    end

    def find_section_preceeding node
      begin
        /(section (\d+) of the)$/ =~ node.previous_node.inner_text.strip
      rescue
        return nil, nil
      end
      return $1, $2
    end

    def find_sections_preceeding node
      /(sections (\d+) to (\d+) of the)$/ =~ node.previous_node.inner_text.strip
      return $1, $2
    end

    def handle_abbreviated_act_references act_abbreviations, clauses
      abbreviations = get_abbreviations(act_abbreviations)
      clauses.each do |clause|
        add_links_to_abbreviations(clause, abbreviations) if contains_acts?(clause)
      end
    end

    ACT_REGEXP = /\sAct\s/

    def contains_acts? clause
      clause.inner_html[ACT_REGEXP]
    end

    def get_act_uri act
      act.statutelaw_url.blank? ? act.opsi_url : act.statutelaw_url
    end

    def get_section_opsi_uri section, act
      section.opsi_url.blank? ? get_act_uri(act) : section.opsi_url
    end

    def get_section_uri section, act
      section.statutelaw_url.blank? ? get_section_opsi_uri(section, act) : section.statutelaw_url
    end

    def find_act citation
      Act.find_by_legislation_url(citation['legislation_url']) || Act.find_by_opsi_url(citation['opsi_url'])
    end

    def get_abbreviations act_abbreviations
      abbreviations = {}
      act_abbreviations.each do |abbreviation|
        abbreviated = abbreviation.at('AbbreviatedActName/text()').to_s
        citation = abbreviation.at('Citation')
        abbreviations[abbreviated] = find_act(citation)
      end
      abbreviations
    end

    def act_cite_attributes act, label=''
      attributes act.legislation_url, get_act_uri(act), label
    end

    def section_cite_attributes act, section_number, sections
      if section = act.find_section_by_number(section_number)
        sections << section
        attributes section.legislation_url, get_section_uri(section, act), section.label
      else
        act_cite_attributes act
      end
    end

    def subsection_cite_attributes act, section, subsection, subsection_number
      legislation_uri = section.legislation_uri_for_subsection(subsection_number)
      attributes legislation_uri, get_section_uri(section, act), subsection
    end

    def find_section act_name, node
      /(section (\d+) of #{act_name})/ =~ node.inner_text
      return reference=$1, number=$2
    end

    def find_sections act_name, node
      /(sections (\d+) to (\d+) of #{act_name})/ =~ node.inner_text
      return reference=$1, number=$2
    end

    def link_section clause, act, sections
      reference, section_number = yield
      if section_number
        add_link(clause, reference) { "<a #{section_cite_attributes(act, section_number, sections)}>#{reference}</a>" }
        true
      else
        false
      end
    end

    def add_act_and_section_links clause, act_name, act, sections
      found_section = link_section(clause, act, sections) { find_sections(act_name, clause) }
      found_section = link_section(clause, act, sections) {  find_section(act_name, clause) } || found_section

      unless found_section
        add_link(clause, act_name) do
          "<a #{act_cite_attributes(act, act.title)}>#{act_name}</a>"
        end
      end
    end

    QUOTED_REGEXP = /“[^”]+”/

    def add_link_to_part clause, name, cite, index
      part = clause.inner_html.split(QUOTED_REGEXP)[index]
      changed = part.gsub(name, "<a #{cite}>#{name}</a>")
      text = clause.inner_html
      clause.inner_html = text.sub(part, changed)
    end

    def insert_subsection_links parts, clause, act, section, subsection_pattern, subsection_number_pattern
      parts.each_with_index do |part, index|
        subsections = part.scan(subsection_pattern).uniq

        subsections.each do |subsection|
          subsection_number = subsection[subsection_number_pattern,1]
          add_link_to_part clause, subsection, subsection_cite_attributes(act, section, subsection, subsection_number), index
        end
      end
    end

    SUBSECTION_REGEXP = /subsection \(\d+\)/
    SUBSECTION_NUMBER_REGEXP = /subsection \((\d+)\)/
    SUBSECTIONS_REGEXP = /subsections \(\d+\) to \(\d+\)/
    SUBSECTIONS_NUMBER_REGEXP = /subsections \((\d+)\) to \(\d+\)/

    def add_subsection_links clause, act, section
      text = clause.inner_html
      parts = text.split(QUOTED_REGEXP)
      insert_subsection_links parts, clause, act, section, SUBSECTION_REGEXP, SUBSECTION_NUMBER_REGEXP
      insert_subsection_links parts, clause, act, section, SUBSECTIONS_REGEXP, SUBSECTIONS_NUMBER_REGEXP
    end

    def add_links_to_abbreviations clause, abbreviations
      acts = []
      sections = []

      abbreviations.keys.each do |name|
        if clause.inner_html[/#{name}/] && (act = abbreviations[name])
          acts << act
          add_act_and_section_links clause, name, act, sections
        end
      end

      if acts.size == 1 && sections.size == 1
        add_subsection_links clause, acts.first, sections.first
      end
    end

end