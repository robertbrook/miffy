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

  def css_class node
    css_class = node.name.gsub('.','_')
    css_class += " #{node['class']}" unless node['class'].blank?
    css_class
  end
  
  def add_html_element name, node, html
    html << %Q|<#{name} class="#{css_class(node)}"|
    html << %Q| id="#{node['id']}"| if node['id']
    if name == 'hr'
      html << " />"
    else
      html << ">"
      node_children_to_html(node, html)
      html << "</#{name}>"
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
  
  def add_link_element node, html
    item = node.inner_text
    url = item[/Act/] ? find_act_url(item) : ''
    html << %Q|<a href="#{url}" class="#{node.name}">|
    node_children_to_html(node, html)    
    html << "</a>"
  end
  
  def handle_clause node, html
    @clause_number = node.at('PgfNumString').inner_text.strip
    clause_id = node['HardReference'].to_s.strip
    unless @clause_number.blank? || clause_id.blank?
      clause_name = "clause#{@clause_number}"
      @clause_anchor_start = %Q|<a id="clause_#{clause_id}" name="#{clause_name}" href="##{clause_name}">|
      html << %Q|<div class="#{css_class(node)}" id="#{node['id']}">|
      node_children_to_html(node, html)
      html << "</div>"
    else
      add_html_element 'div', node, html
    end
  end
  
  def handle_pgf_num_string node, html
    if @clause_anchor_start
      html << %Q|<span class="#{css_class(node)}>"|
      html << @clause_anchor_start
      node_children_to_html(node, html)
      html << '</a>'
      html << %Q|</span>"|
      @clause_anchor_start = nil
    else
      add_html_element 'span', node, html
    end
  end
  
  def node_to_html(node, html)
    case node.name.gsub('.','_')
      when /Citation/
        add_link_element node, html
      when /_number$/
        add_html_element 'span', node, html
      when /^PgfNumString_\d+$/
        handle_pgf_num_string node, html
      when /_PgfTag$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'p')
        @in_paragraph = true
        add_html_element(tag, node, html)
        @in_paragraph = false unless already_in_paragraph
      when 'ParaLineStart'
        line = node['LineNum'].to_s
        html << %Q|<br />| if @in_para_line
        html << %Q|<a name="page#{@page_number}-line#{line}"></a>|
        @in_para_line = true

      when /^(Para|PageStart)$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'div')
        add_html_element(tag, node, html)
        if node.name == 'PageStart' && already_in_paragraph
          line = html.pop
          line += '<br />'
          html << line
        end
        if node.name == 'PageStart'
          end_tag = html.pop
          text = html.pop
          page = text[/Page (.+)/]
          if page
            @page_number = $1
            anchor = page.sub(' ','').downcase
            text.sub!(page, %Q|<a href="##{anchor}" name="#{anchor}">#{page}</a>|)
          end
          html << text
          html << end_tag          
        end
        
      when /^(SubPara_sch|SubSubPara_sch|ResolutionPara|)$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'p')
        @in_paragraph = true
        add_html_element(tag, node, html)
        @in_paragraph = false unless already_in_paragraph
        
      when /^(Clause)$/
        handle_clause node, html
      
      when /^(Clause_ar)$/
        @clause_ref = node['HardReference']
        add_html_element 'div', node, html
        
      when /^(Clause_ar_text)$/
        add_html_element 'span', node, html
        
        end_tag = html.pop
        last_line = html.pop
        clause_file = Dir.glob(RAILS_ROOT + '/spec/fixtures/Clauses.mif')
        html << %Q|<a href="convert?file=#{clause_file}#clause_#{@clause_ref}">|
        html << last_line
        html << "</a>"
        html << end_tag

      when DIV_RE
        add_html_element 'div', node, html
      when SPAN_RE
        add_html_element 'span', node, html
      when UL_RE
        add_html_element 'ul', node, html
      when LI_RE
        add_html_element 'li', node, html
      when HR_RE
        add_html_element("hr", node, html) 
      when TR_RE
        add_html_element("tr", node, html)
      when TH_RE
        add_html_element("th", node, html)
      when TD_RE
        add_html_element("td", node, html)
      when TABLE_RE
        add_html_element("table", node, html)
      else
        raise node.name
        node_children_to_html(node, html)
    end if node.elem?

    if node.text?
      html << node.to_s.gsub("/n", "<br />")
    end
  end
end