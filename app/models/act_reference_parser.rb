require 'rubygems'
require 'hpricot'

class ActReferenceParser

  def parse_xml_file xml_file, options={}
    parse_xml(IO.read(xml_file), options)
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    doc.to_s
  end

end