require 'mifparserutils'
require 'htmlentities'
require 'open-uri'
require 'hpricot'

class Mif2HtmlParser

  include MifParserUtils

  class << self

    NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX  = Regexp.new('(\s+)(\S+)\n(\s+)%span\.(\S+)_number\n(\s+)(\S+)\n(\s+),', Regexp::MULTILINE)
    MOVE_ANCHOR_BEFORE_NUMBER_SPAN_REGEX = Regexp.new('\n(\s+)(\S+Number)\n(\s+)\s\s(%a\{[^\}]+\})\n', Regexp::MULTILINE)

    def format_haml haml
      haml.gsub!(NEED_SPACE_BETWEEN_LABEL_AND_NUMBER_REGEX,  '\1\2 <span class="\4_number">\6</span>,')    
      haml.gsub!(MOVE_ANCHOR_BEFORE_NUMBER_SPAN_REGEX, "\n" + '\3\4' + "\n" + '\1\2' + "\n")
      haml.gsub!(/(Letter|FrameData|Dropcap|Bold|\w+_number|PgfNumString_\d|(clause_.+\}))\n/, '\1' + "<>\n")
      haml.gsub!(/(^\s*(#|%).+(SmallCaps|\}|PgfNumString|\w+_text|PageStart|Number|Page|Line|Sponsor|AmendmentNumber_PgfTag))\n/, '\1' + "<\n")
      
      haml
    end
    
  end
  
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
    
    Mif2HtmlParser.format_haml(haml)
  end

  def generate_html doc, options
    if options[:body_only]
      @html = []
      doc_to_html(doc)
    else
      @html = ['<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>']
      doc_to_html(doc)
      add ['</body></html>'] 
    end

    result = @html.join('')
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

  def doc_to_html(doc)
    @in_paragraph = false
    node_children_to_html(doc.root)
  end

  def node_children_to_html(node)
    node.children.each do |child|
      node_to_html(child)
    end if node.children
  end

  def css_class node
    css_class = node.name.gsub('.','_')
    css_class += " #{node['class']}" unless node['class'].blank?
    css_class
  end
  
  def add_html_element name, node
    add %Q|<#{name} class="#{css_class(node)}"|
    add %Q| id="#{node['id']}"| if node['id']
    if name == 'hr'
      add " />"
    else
      add ">"
      node_children_to_html(node)
      add "</#{name}>"
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
  
  def add_link_element node
    item = node.inner_text
    url = item[/Act/] ? find_act_url(item) : ''
    add %Q|<a href="#{url}" class="#{node.name}">|
    node_children_to_html(node)    
    add "</a>"
  end
  
  def handle_clause node
    @clause_number = node.at('PgfNumString').inner_text.strip
    clause_id = node['HardReference'].to_s.strip
    unless @clause_number.blank? || clause_id.blank?
      clause_name = "clause#{@clause_number}"
      @clause_anchor_start = %Q|<a id="clause_#{clause_id}" name="#{clause_name}" href="##{clause_name}">|
      add %Q|<div class="#{css_class(node)}" id="#{node['id']}">|
      node_children_to_html(node)
      add "</div>"
    else
      add_html_element 'div', node
    end
  end
  
  def handle_pgf_num_string node
    if @clause_anchor_start
      add %Q|<span class="#{css_class(node)}">|
      add @clause_anchor_start
      node_children_to_html(node)
      add '</a>'
      add %Q|</span>|
      @clause_anchor_start = nil
    else
      add_html_element 'span', node
    end
  end
  
  def handle_pdf_tag node
    already_in_paragraph = @in_paragraph
    tag = (already_in_paragraph ? 'span' : 'p')
    @in_paragraph = true
    add_html_element(tag, node)
    @in_paragraph = false unless already_in_paragraph
  end
  
  def handle_para_line_start node
    line = node['LineNum'].to_s
    add %Q|<br />| if @in_para_line
    add %Q|<a name="page#{@page_number}-line#{line}"></a>|
    @in_para_line = true
  end

  def handle_para node
    already_in_paragraph = @in_paragraph
    tag = (already_in_paragraph ? 'span' : 'div')
    add_html_element(tag, node)
    already_in_paragraph
  end

  def handle_page_start node
    already_in_paragraph = handle_para node        
    if node.name == 'PageStart' && already_in_paragraph
      line = @html.pop
      line += '<br />'
      add line
    end
    if node.name == 'PageStart'
      end_tag = @html.pop
      text = @html.pop
      page = text[/Page (.+)/]
      if page
        @page_number = $1
        anchor = page.sub(' ','').downcase
        text.sub!(page, %Q|<a href="##{anchor}" name="#{anchor}">#{page}</a>|)
      end
      add text
      add end_tag
    end
  end
  
  def handle_sub_para_variants node
    already_in_paragraph = @in_paragraph
    tag = (already_in_paragraph ? 'span' : 'p')
    @in_paragraph = true
    add_html_element(tag, node)
    @in_paragraph = false unless already_in_paragraph
  end

  def handle_clause_ar node
    @clause_ref = node['HardReference']
    add_html_element 'div', node
  end

  def handle_clause_ar_text node
    add_html_element 'span', node
    
    end_tag = @html.pop
    last_line = @html.pop
    clause_file = Dir.glob(RAILS_ROOT + '/spec/fixtures/Clauses.mif')
    add %Q|<a href="convert?file=#{clause_file}#clause_#{@clause_ref}">|
    add last_line
    add "</a>"
    add end_tag
  end
  
  def add text
    if text.nil?
      raise 'text should not be null'
    else
      @html << text
    end
  end

  def node_to_html(node)
    case node.name.gsub('.','_')
      when 'Citation'
        add_link_element node
      when 'ParaLineStart'
        handle_para_line_start node
      when 'Para'
        handle_para node
      when 'PageStart'
        handle_page_start node
      when 'Clause'
        handle_clause node  
      when 'Clause_ar'
        handle_clause_ar node
      when 'Clause_ar_text'
        handle_clause_ar_text node
      when /_number$/
        add_html_element 'span', node
      when /^PgfNumString_\d+$/
        handle_pgf_num_string node
      when /_PgfTag$/
        handle_pdf_tag node
      when /^(SubPara_sch|SubSubPara_sch|ResolutionPara|)$/
        handle_sub_para_variants node
      when DIV_RE
        add_html_element 'div', node
      when SPAN_RE
        add_html_element 'span', node
      when UL_RE
        add_html_element 'ul', node
      when LI_RE
        add_html_element 'li', node
      when HR_RE
        add_html_element 'hr', node 
      when TR_RE
        add_html_element 'tr', node
      when TH_RE
        add_html_element 'th', node
      when TD_RE
        add_html_element 'td', node
      when TABLE_RE
        add_html_element 'table', node
      else
        raise node.name
        node_children_to_html(node)
    end if node.elem?

    if node.text?
      add node.to_s.gsub("/n", "<br />")
    end
  end
end