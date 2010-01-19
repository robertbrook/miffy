class TocToEpubParser
  
  def toc_file_type doc
    if !(doc/'TOC/Clause').to_s.blank?
      "clauses"
    elsif !(doc/'TOC/Schedule').to_s.blank?
      "schedules"
    else
      "unknown"
    end
  end
  
  
  def create_opf xml
    doc = Hpricot.XML(xml)
    opf = []
    if toc_file_type(doc) == 'clauses'
      opf << '<?xml version="1.0" encoding="UTF-8"?>'
      opf << '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="UKParliamentBills">'
      
      opf << '<metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/">'
      opf << '<dc:language>en</dc:language>'
      opf << '<dc:title>' + (doc/'TOC/Title/text()').to_s + '</dc:title>'
      opf << '<dc:creator>UK Parliament</dc:creator>'
      opf << '<dc:publisher>UK Parliament</dc:publisher>'
      opf << '<dc:rights>This Bill has been published subject to Parliamentary Copyright</dc:rights>'
      opf << '</metadata>'
      
      opf << '<manifest>'
      opf << '<item id="clause-css" href="css/clauses.css" media-type="text/css" />'
      opf << '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />'
      opf << '<item id="intro" href="introduction.html" media-type="application/xhtml+xml"/>' unless (doc/'TOC/Introduction').to_s.blank?
      (doc/'TOC/Clause').each do |clause|
        opf << '<item id="clause' + clause.attributes['number'] + '" href="clause' + clause.attributes['number'] + '.html" media-type="application/xhtml+xml" />'
      end
      opf << '</manifest>'
      
      opf << '<spine toc="ncx">'
      opf << '<itemref idref="intro" />' unless (doc/'TOC/Introduction').to_s.blank?
      (doc/'TOC/Clause').each do |clause|
        opf << '<itemref idref="clause' + clause.attributes['number'] + '" />'
      end
      opf << '</spine>'
      
      opf << '</package>'
    end
    opf.to_s
  end
end