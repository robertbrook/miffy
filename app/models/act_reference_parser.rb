require 'rubygems'
require 'hpricot'

class ActReferenceParser

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

    act_abbreviations = (doc/'/Document/BillData/Interpretation/ActAbbreviation')
    handle_abbreviated_act_references(act_abbreviations, doc) unless act_abbreviations.empty?

    act_citations = (doc/'/Document/BillData/Clauses/Clause/ClauseText//Citation')
    handle_act_citation_references(act_citations, doc) unless act_citations.empty?

    no_references = (act_abbreviations.empty? && act_citations.empty?)
    no_references ? xml : doc.to_s
  end

  private

    def handle_act_citation_references act_citations, doc
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
      /(section (\d+) of the)$/ =~ node.previous_node.inner_text.strip
      return $1, $2
    end

    def find_sections_preceeding node
      /(sections (\d+) to (\d+) of the)$/ =~ node.previous_node.inner_text.strip
      return $1, $2
    end

    def handle_abbreviated_act_references act_abbreviations, doc
      abbreviations = get_abbreviations(act_abbreviations)
      clauses = (doc/'ClauseText')
      clauses.each do |clause|
        add_links(clause, abbreviations) if contains_acts?(clause)
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

    def add_links clause, abbreviations
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