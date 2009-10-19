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
    if act_abbreviations.size == 0
      xml
    else
      abbreviations = get_abbreviations(act_abbreviations)
      clauses = (doc/'ClauseText')
      clauses.each do |clause|
        add_links(clause, abbreviations) if contains_acts?(clause)
      end
      doc.to_s
    end
  end

  private

    def contains_acts? clause
      clause.inner_html[/\sAct\s/]
    end

    def get_act_uri act
      act.statutelaw_url.blank? ? act.opsi_url : act.statutelaw_url
    end

    def get_section_uri section, act
      if section.statutelaw_url.blank?
        if section.opsi_url.blank?
          get_act_uri(act)
        else
          section.opsi_url
        end
      else
        section.statutelaw_url
      end
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

    def subsection_cite_attributes act, section, subsection
      subsection_number = subsection[/subsection \((\d+)\)/,1]
      legislation_uri = section.legislation_uri_for_subsection(subsection_number)
      attributes legislation_uri, get_section_uri(section, act), subsection
    end

    def add_link clause, name, cite
      html = clause.inner_html
      changed = html.gsub(name, "<a #{cite}>#{name}</a>")
      clause.inner_html = changed
    end

    def add_act_and_section_links clause, name, act, sections
      section_reference = false
      if clause.inner_html[/(sections (\d+) to (\d+) of #{name})/]
        add_link clause, name=$1, section_cite_attributes(act, section_number=$2, sections)
        section_reference = true
      end

      if clause.inner_html[/(section (\d+) of #{name})/]
        add_link clause, name=$1, section_cite_attributes(act, section_number=$2, sections)
        section_reference = true
      end

      add_link clause, name, act_cite_attributes(act, act.title) unless section_reference
    end

    def add_link_to_part clause, name, cite, index
      part = clause.inner_html.split(/“[^”]+”/)[index]
      changed = part.gsub(name, "<a #{cite}>#{name}</a>")
      text = clause.inner_html
      clause.inner_html = text.sub(part, changed)
    end

    def add_subsection_links clause, act, section
      text = clause.inner_html
      parts = text.split(/“[^”]+”/)

      parts.each_with_index do |part, index|
        subsections = part.scan(/subsection \(\d+\)/).uniq

        subsections.each do |subsection|
          add_link_to_part clause, subsection, subsection_cite_attributes(act, section, subsection), index
        end
      end
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