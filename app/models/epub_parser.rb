require 'rexml/document'

class EpubParser
  
  def create_epub contents_xml, mif_xml
    opf = create_opf(contents_xml)
    ncx = create_ncx(contents_xml)
    
    contents_page = create_contents_html(contents_xml)    
    intro_page    = create_html_page(mif_xml, ["Clauses/Rubric", "Clauses/Prelim"])
        
    pages = []
    
    doc = Hpricot.XML(contents_xml)    
    (doc/'TOC/Clause').each do |clause|
      pages << create_html_page(mif_xml, ["//Clause[@id='#{clause.attributes['clause_id']}]'"])
    end
    
    filename = (doc/'TOC/Title/text()').to_s.gsub(" ", "-").gsub("[", "").gsub("]","")
    
    folder = "#{RAILS_ROOT}/tmp/epub-#{filename}"
    if !FileTest.exist?(folder)
      `mkdir "#{folder}"`
    end
    File.open("#{folder}/content.opf",'w') {|f| f.write opf }
    File.open("#{folder}/toc.ncx",'w') {|f| f.write ncx }
    File.open("#{folder}/contents.html",'w') {|f| f.write contents_page }
    File.open("#{folder}/introduction.html",'w') {|f| f.write intro_page }
    i = 0
    pages.each do |page|
      i+=1
      File.open("#{folder}/clause#{i}.html",'w') {|f| f.write page }
    end
    
    pubfile = "#{filename}.epub"
    
    cmd = %Q|cp -rf "#{RAILS_ROOT}/data/epub_files/" "#{folder}"|
    
    `#{cmd}`
    puts cmd
    `rm "#{folder}/#{pubfile}"`
    `cd #{folder}; zip "#{pubfile}" mimetype`
    `cd #{folder}; zip -u "#{pubfile}" *.html`
    `cd #{folder}; zip -u "#{pubfile}" *.opf`
    `cd #{folder}; zip -u "#{pubfile}" *.ncx`
    `cd #{folder}; zip -u "#{pubfile}" css/clauses.css`
    `cd #{folder}; zip -ur "#{pubfile}" META-INF`
    
    `cp -f "#{folder}/#{pubfile}" "#{RAILS_ROOT}/public/epub/"`
  end
  
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
      opf << '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="UKParliamentBills">' + "\n"
      
      opf << '  <metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/">' + "\n"
      opf << '    <dc:language>en</dc:language>' + "\n"
      opf << '    <dc:title>' + cleanup_text((doc/'TOC/Title/text()').to_s) + '</dc:title>' + "\n"
      opf << '    <dc:creator>UK Parliament</dc:creator>' + "\n"
      opf << '    <dc:publisher>UK Parliament</dc:publisher>' + "\n"
      opf << '    <dc:rights>This Bill has been published subject to Parliamentary Copyright</dc:rights>' + "\n"
      opf << '  </metadata>' + "\n"
      
      opf << '  <manifest>' + "\n"
      opf << '    <item id="clause-css" href="css/clauses.css" media-type="text/css" />' + "\n"
      opf << '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />' + "\n"
      opf << '    <item id="contents" href="contents.html" media-type="application/xhtml+xml"/>' + "\n"
      opf << '    <item id="intro" href="introduction.html" media-type="application/xhtml+xml"/>' + "\n" unless (doc/'TOC/Introduction').to_s.blank?
      (doc/'TOC/Clause').each do |clause|
        opf << '    <item id="clause' + clause.attributes['number'] + '" href="clause' + clause.attributes['number'] + '.html" media-type="application/xhtml+xml" />' + "\n"
      end
      opf << '  </manifest>' + "\n"
      
      opf << '  <spine toc="ncx">' + "\n"
      opf << '    <itemref idref="contents" />' + "\n"
      opf << '    <itemref idref="intro" />' + "\n" unless (doc/'TOC/Introduction').to_s.blank?
      (doc/'TOC/Clause').each do |clause|
        opf << 'qq<itemref idref="clause' + clause.attributes['number'] + '" />' + "\n"
      end
      opf << '  </spine>' + "\n"
      
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
      ncx << %Q|  <meta name="dtb:uid" content="#{uuid}"/>\n|
      ncx << '  <meta name="dtb:depth" content="1"/>' + "\n"
      ncx << '  <meta name="dtb:totalPageCount" content="0"/>' + "\n"
      ncx << '  <meta name="dtb:maxPageNumber" content="0"/>' + "\n"
      ncx<< '</head>' + "\n"

      ncx << '<docTitle>'
      ncx << '  <text>' + cleanup_text((doc/'TOC/Title/text()').to_s) + '</text>' + "\n"
      ncx << '</docTitle>'

      ncx << '<navMap>'
      
      ncx << %Q|<navPoint id="navPoint-1" playOrder="1">|
      ncx << '<navLabel>'
      ncx << %Q|<text>Contents</text>|
      ncx << '</navLabel>'
      ncx << %Q|<content src="contents.html"/>|
      ncx << '</navPoint>'
      
      ncx << %Q|<navPoint id="navPoint-2" playOrder="2">|
      ncx << '<navLabel>'
      ncx << %Q|<text>Introduction</text>|
      ncx << '</navLabel>'
      ncx << %Q|<content src="introduction.html"/>|
      ncx << '</navPoint>'
      
      i = 2
      (doc/'TOC/Clause').each do |clause|
        i+=1
        clause_number = clause.attributes['number']
        ncx << %Q|<navPoint id="navPoint-#{i}" playOrder="#{i}">|
        ncx << '<navLabel>'
        ncx << %Q|<text>Clause #{cleanup_text((clause/'text()').to_s)}</text>|
        ncx << '</navLabel>'
        ncx << %Q|<content src="clause#{clause_number}.html"/>|
        ncx << '</navPoint>'
      end
      ncx << '</navMap>'
      ncx << '</ncx>'
    end
    ncx.to_s
  end
  
  def create_contents_html xml
    doc = Hpricot.XML(xml)
    html = []
    if toc_file_type(doc) == 'clauses'
      html << '<?xml version="1.0" encoding="UTF-8"?>'
      html << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
      html << '<html xmlns="http://www.w3.org/1999/xhtml">'
      
      html << '<head>' + "\n"
      html << %Q| <title>#{cleanup_text((doc/'TOC/Title/text()').to_s)}</title>\n|
      html << ' <link rel="stylesheet" type="text/css" href="css/clauses.css" />' + "\n"
      html << '</head>'
      
      html << '<body>'
      html << ' <div id="table-of-contents">' + "\n"
      
      html << %Q|   <h1>#{cleanup_text((doc/'TOC/Title/text()').to_s)}</h1>\n|
      html << %Q|   <h2>Table of Contents</h2>\n|
      
      (doc/'TOC/').each do |node|
        case node.name
          when /Introduction/
            html << %Q|   <a href="introduction.html" class="intro">Introduction</a><br />\n|
          when /Part/
            html << %Q|   <h3>#{cleanup_text((node/'text()').to_s)}</h3>\n|
          when /CrossHeading/
            html << %Q|   <h4>#{cleanup_text((node/'text()').to_s)}</h4>\n|
          when /Clause/
            clause_number = node.attributes['number']
            html << %Q|   <a href="clause#{clause_number}.html">Clause #{cleanup_text((node/'text()').to_s)}</a><br />\n|
        end
      end
      
      html << ' </div>'
      html << '</body>'
      
      html << '</html>'
    end
    html.to_s
  end
  
  def create_html_page(xml, sections)
    doc = Hpricot.XML(xml)
    section_xml = []
    section_xml << "<Document><BillData>"
    section_xml << "<BillTitle>#{(doc/'BillData/BillTitle/text()').to_s}</BillTitle>"
  
    sections.each do |section|
      if section[0..1] == "//"
        flag = true
        section_xml << (doc/"#{section[2..-1]}").first.to_s
      else
        section_xml << (doc/"BillData/#{section}").to_s
      end
    end
  
    section_xml << "</BillData></Document>"
        
    mif_parser = MifToHtmlParser.new
    html = []
    html << '<?xml version="1.0" encoding="UTF-8"?>'
    html << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
    html << '<html xmlns="http://www.w3.org/1999/xhtml">'
    
    html << '<head>'
    html << %Q| <title>#{(doc/'BillData/BillTitle/text()').to_s}</title>\n|
    html << ' <link rel="stylesheet" type="text/css" href="css/clauses.css" />' + "\n"
    html << '</head>'
    html << '<body>'
    html << mif_parser.parse_xml(section_xml.to_s, {:format => :html, :body_only => true})
    html << '</body>'
    html << '</html>'
    html.to_s
  end
  
  def cleanup_text text
    text.gsub!("&#xE2;&#x80;&#x99;","'")
    text.gsub!("&#xE2;&#x80;&#x9C;",'"')
    text.gsub!("&#xE2;&#x80;&#x9D;",'"')
    text
  end
end