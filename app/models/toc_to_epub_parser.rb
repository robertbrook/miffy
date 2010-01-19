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
  
  def create_ncx xml
    doc = Hpricot.XML(xml)
    ncx = []
    if toc_file_type(doc) == 'clauses'
      ncx << '<?xml version="1.0" encoding="UTF-8"?>'
      ncx << '<ncx xmlns:calibre="http://calibre.kovidgoyal.net/2009/metadata" xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="en">'

      ncx << '<head>'
      uuid = `uuidgen`.strip
      ncx << %Q|<meta name="dtb:uid" content="#{uuid}"/>|
      ncx << '<meta name="dtb:depth" content="1"/>'
      ncx << '<meta name="dtb:totalPageCount" content="0"/>'
      ncx << '<meta name="dtb:maxPageNumber" content="0"/>'
      ncx<< '</head>'

      ncx << '<docTitle>'
      ncx << '<text>' + (doc/'TOC/Title/text()').to_s + '</text>'
      ncx << '</docTitle>'

      ncx << '<navMap>'
      (doc/'TOC/Clause').each do |clause|
        clause_number = clause.attributes['number']
        ncx << %Q|<navPoint id="navPoint-#{clause_number}" playOrder="#{clause_number}">|
        ncx << '<navLabel>'
        ncx << %Q|<text>Clause #{(clause/'text()').to_s}</text>|
        ncx << '</navLabel>'
        ncx << %Q|<content src="clause#{clause_number}.html"/>|
        ncx << '</navPoint>'
      end
      ncx << '</navMap>'
      ncx << '</ncx>'
    end
    ncx.to_s
  end
end