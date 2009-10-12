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
        add_links clause, abbreviations
      end
      doc.to_s
    end
  end

  private
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

    def act_cite_attributes act, label=''
      attributes act.legislation_url, get_act_uri(act), label
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

    def get_cite_attributes html, act, name
      if html[/(section (\d+) of #{name})/]
        name = $1
        section_number = $2
        if section = act.find_section_by_number(section_number)
          attributes section.legislation_url, get_section_uri(section, act), section.label
        else
          act_cite_attributes act
        end
      else
        act_cite_attributes act, act.title
      end
    end

    def add_links clause, abbreviations
      html = clause.inner_html
      if html[/\sAct\s/]
        abbreviations.keys.each do |name|
          if html[/#{name}/] && (act = abbreviations[name])
            cite = get_cite_attributes html, act, name
            changed = html.gsub(name, "<a #{cite}>#{name}</a>")
            clause.inner_html = changed
          end
        end
      end
    end

end