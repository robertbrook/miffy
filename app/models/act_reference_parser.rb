require 'rubygems'
require 'hpricot'

class ActReferenceParser

  def parse_xml_file xml_file, options={}
    parse_xml(IO.read(xml_file), options)
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    act_abbreviations = (doc/'/Document/BillData/Interpretation/ActAbbreviation')
    if act_abbreviations.size == 0
      xml
    else
      abbreviations = {}
      act_abbreviations.each do |abbreviation|
        abbreviated = abbreviation.at('AbbreviatedActName/text()').to_s
        citation = abbreviation.at('Citation')
        abbreviations[abbreviated] = citation
      end

      clauses = (doc/'ClauseText')
      clauses.each do |clause|
        html = clause.inner_html
        if html[/\sAct\s/]
          abbreviations.keys.each do |name|
            if html[/#{name}/]
              citation = abbreviations[name]
              if html[/(section (\d+) of #{name})/]
                cite = %Q|rel="cite" resource="#{citation['legislation_url']}/#{$2}" href="#{citation['opsi_url']}"|
                changed = html.gsub($1, "<a #{cite}>#{$1}</a>")
                clause.inner_html = changed
              else
                cite = %Q|rel="cite" resource="#{citation['legislation_url']}" href="#{citation['opsi_url']}"|
                changed = html.gsub(name, "<a #{cite}>#{name}</a>")
                clause.inner_html = changed
              end
            end
          end
        end
      end
      doc.to_s
    end
  end

end