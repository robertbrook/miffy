require 'mifparserutils'
require 'htmlentities'
require 'open-uri'
require 'hpricot'

class Mif2HtmlParser

  include MifParserUtils

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    parse_xml(IO.read(xml_file), options)
  end

  def parse_xml xml, options={:format => :html}
    doc = Hpricot.XML xml
    format = options[:format]
    if format == :html
      generate_html doc, options
    elsif format == :haml
      html = generate_html doc, options
      generate_haml html, options
    end
  end

  def generate_haml html, options
    html_file = Tempfile.new("#{Time.now.to_i.to_s}.html", "#{RAILS_ROOT}/tmp")
    html_file.write html
    html_file.close
    cmd = "html2haml #{html_file.path}"
    haml = `#{cmd}`
    html_file.delete
    
    format_haml(haml)
  end

  def format_haml haml
    reg_exp = Regexp.new('(Number|Page|Line)\n(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n(\s+),', Regexp::MULTILINE)
    haml.gsub!(reg_exp, '\1' + "\n" + '\2\3 <span class="\5_number">\7</span>,')
    haml.gsub!(/(Letter|FrameData|Dropcap|Bold|\w+_number|PgfNumString_\d)\n/, '\1' + "<>\n")
    haml.gsub!(/(SmallCaps|\}|PgfNumString|\w+_text|PageStart|Number|Page|Line|Sponsor|AmendmentNumber_PgfTag)\n/, '\1' + "<\n")
    haml
  end
  
  def generate_html doc, options
    if options[:body_only]
      result = doc_to_html(doc, [])
    else
      result = ['<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>']
      doc_to_html(doc, result)
      result << ['</body></html>'] 
    end

    result = result.join('')
    begin
      doc = REXML::Document.new(result)
    rescue Exception => e
      puts e.to_s
    end
    if options[:indent]
      indented = ''
      doc.write(indented,2)
      indented
    else
      result
    end
  end
  
  def get_html_for_char element
    char = get_char(element)
    if char == "\n"
      "<br />"
    else
      HTMLEntities.new.encode(char)
    end
  end

  DIV = %w[Amendments_Commons Head HeadConsider Date
      Committee Clause_Committee Resolution Order_Committee Schedule_Committee
      CrossHeadingSch Amendment
      OrderCrossHeading
      NewClause_Committee Order_House
      Arrangement
      Rubric
      Cover
      BillData
      CoverHeading
      CoverPara
      Heading_ar
      Head_thin
      HeadNotice
      NoticeOfAmds
      Given
      Schedules_ar
      SchedulesTitle_ar
      Prelim
      ABillTo Abt1 Abt2 Abt3 Abt4 LongTitle Bpara WordsOfEnactment
      Clauses  
      Clauses_ar
      Amendment_Text Amendment_Number
      ClauseText Heading_text
      CrossHeadingTitle ClauseTitle
      OrderText OrderAmendmentText
      Order_Motion OrderHeading
      ResolutionHead ResolutionText
      OrderPreamble ResolutionPreamble
      Stageheader
      CommitteeShorttitle
      MarshalledOrderNote
      ClausesToBeConsidered
      Para_sch
      BillTitle
      Move
      Motion
      Text_motion
      Table
      Footer
      SubSection].inject({}){|h,v| h[v]=true; h}
  DIV_RE = Regexp.new "(^#{DIV.keys.join("$|")}$)"

  # P = %w[].inject({}){|h,v| h[v]=true; h}
  
  TABLE = %w[TableData].inject({}){|h,v| h[v]=true; h}
  TABLE_RE = Regexp.new "(^#{TABLE.keys.join("$|")}$)"

  TR = %w[Row].inject({}){|h,v| h[v]=true; h}
  TR_RE = Regexp.new "(^#{TR.keys.join("$|")}$)"
  
  TH = %w[CellH].inject({}){|h,v| h[v]=true; h}
  TH_RE = Regexp.new "(^#{TH.keys.join("$|")}$)"
  
  TD = %w[Cell].inject({}){|h,v| h[v]=true; h}
  TD_RE = Regexp.new "(^#{TD.keys.join("$|")}$)"

  SPAN = %w[ResolutionPara ResolutionSubPara
      SubPara
      SubPara_sch
      SubSubPara_sch
      Definition
      TextContinuation
      PgfNumString
      OrderDate
      ResolutionDate
      OrderPara
      SubSection_text
      ResolutionHead_text
      Number_text
      ResolutionText_text
      ResolutionPara_text
      ResolutionSubPara_text
      Page_text
      Para_text
      Line_text
      ClauseTitle_text
      Amendment_Text_text
      Para_sch_text
      TextContinuation_text
      Proposer_name
      Day Date_text STText Notehead NoteTxt
      STHouse
      STLords
      STCommons
      Citation
      Letter
      Enact
      Italic
      SmallCaps
      Dropcap
      Bold
      Bold_text
      WHITESPACE
      FrameData
      Number Page Line ].inject({}){|h,v| h[v]=true; h}
  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"

  HR = %w[Separator_thick Separator_thin].inject({}){|h,v| h[v]=true; h}
  HR_RE = Regexp.new "(#{HR.keys.join("|")})"

  def doc_to_html(doc, xml)
    @in_paragraph = false
    node_children_to_html(doc.root, xml)
    xml
  end

  def node_children_to_html(node, xml)
    node.children.each do |child|
      node_to_html(child, xml)
    end if node.children
  end

  def add_html_element name, node, xml
    unless node['class'].blank?
      xml << %Q|<#{name} class="#{node.name.gsub('.','_')} #{node['class']}"|
    else
      xml << %Q|<#{name} class="#{node.name.gsub('.','_')}"|
    end
    xml << %Q| id="#{node['id']}"| if node['id']
    if name == 'hr'
      xml << " />"
    else
      xml << ">"
      node_children_to_html(node, xml)
      xml << "</#{name}>"
    end
    unless node.name == 'SmallCaps'
      @in_para_line = false
    end
  end

  def find_act_url act_name
    search_url = "http://search.opsi.gov.uk/search?q=#{URI.escape(act_name)}&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection"
    begin
      doc = Hpricot.XML open(search_url)
      url = nil
      
      (doc/'R/T').each do |result|
        term = result.inner_text.gsub(/<[^>]+>/,'')
        if act_name == term
          url = result.at('../U/text()').to_s
        end
      end
      
      url
    rescue Exception => e
      puts 'error retrieving: ' + search_url
      puts e.class.name
      puts e.to_s
      nil
    end
  end
  
  def add_link_element node, xml
    item = node.inner_text
    url = item[/Act/] ? find_act_url(item) : ''
    xml << %Q|<a href="#{url}" class="#{node.name}">|
    node_children_to_html(node, xml)    
    xml << "</a>"
  end
  
  def node_to_html(node, xml)
    case node.name.gsub('.','_')
      when /Citation/
        add_link_element node, xml
      when /_number$/
        add_html_element 'span', node, xml
      when /^PgfNumString_\d+$/
        add_html_element 'span', node, xml
      when /_PgfTag$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'p')
        @in_paragraph = true
        add_html_element(tag, node, xml)
        @in_paragraph = false unless already_in_paragraph
      when 'ParaLineStart'
        line = node['LineNum'].to_s
        xml << %Q|<br />| if @in_para_line
        xml << %Q|<a name="page#{@page_number}-line#{line}"></a>|
        @in_para_line = true

      when /^(Para|PageStart)$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'div')
        add_html_element(tag, node, xml)
        if node.name == 'PageStart' && already_in_paragraph
          line = xml.pop
          line += '<br />'
          xml << line
        end
        if node.name == 'PageStart'
          end_tag = xml.pop
          text = xml.pop
          page = text[/Page (.+)/]
          if page
            @page_number = $1
            anchor = page.sub(' ','').downcase
            text.sub!(page, %Q|<a href="##{anchor}" name="#{anchor}">#{page}</a>|)
          end
          xml << text
          xml << end_tag          
        end
        
      when /^(SubPara_sch|SubSubPara_sch|ResolutionPara|)$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'p')
        @in_paragraph = true
        add_html_element(tag, node, xml)
        @in_paragraph = false unless already_in_paragraph
        
      when /^(Clause)$/
        clause_num = get_clause_num(node).to_s
        clause_id = get_clause_id(node).to_s
        unless clause_num.empty? || clause_id.empty?
          xml << %Q|<div class="#{node.name.gsub('.','_')}" id="#{node['id']}">|
          xml << %Q|<a id="clause_#{clause_id}" name="clause#{clause_num}"></a>|
          node_children_to_html(node, xml)
          xml << "</div>"
        else
          add_html_element 'div', node, xml
        end
      
      when /^(Clause_ar)$/
        @clause_ref = node.attributes['HardReference']
        add_html_element 'div', node, xml
        
      when /^(Clause_ar_text)$/
        add_html_element 'span', node, xml
        
        end_tag = xml.pop
        last_line = xml.pop
        clause_file = Dir.glob(RAILS_ROOT + '/spec/fixtures/Clauses.mif')
        xml << %Q|<a href="convert?file=#{clause_file}#clause_#{@clause_ref}">|
        xml << last_line
        xml << "</a>"
        xml << end_tag

      when DIV_RE
        add_html_element 'div', node, xml
      when SPAN_RE
        add_html_element 'span', node, xml
      when UL_RE
        add_html_element 'ul', node, xml
      when LI_RE
        add_html_element 'li', node, xml
      when HR_RE
        add_html_element("hr", node, xml) 
      when TR_RE
        add_html_element("tr", node, xml)
      when TH_RE
        add_html_element("th", node, xml)
      when TD_RE
        add_html_element("td", node, xml)
      when TABLE_RE
        add_html_element("table", node, xml)
      else
        raise node.name
        node_children_to_html(node, xml)
    end if node.elem?

    if node.text?
      xml << node.to_s.gsub("/n", "<br />")
    end
  end

  def get_clause_num xml
    doc = Hpricot.XML xml.to_s
    (doc/'ClauseTitle'/'ClauseTitle_PgfTag'/'PgfNumString'/'PgfNumString_1/'/'text()')
  end
  
  def get_clause_id xml
    doc = Hpricot.XML xml.to_s
    element = (doc/'Clause')
    if element && element.first && !element.first.attributes.nil?
      element.first.attributes['HardReference']
    else
      ''
    end
  end
end