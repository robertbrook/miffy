require 'mifparserutils'
require 'htmlentities'
require 'open-uri'
require 'hpricot'
require 'mechanize'

class MifToHtmlParser

  include MifParserUtils

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    parse_xml(IO.read(xml_file), options)
  end

  def parse_xml xml, options={:format => :html}
    doc = Hpricot.XML xml
    format = options[:format]
    @clauses_file = options[:clauses_file]
    if format == :html
      generate_html doc, options
    elsif format == :haml
      html = generate_html doc, options
      generate_haml html, options
    elsif format == :text
      html = generate_html doc, options
      html.gsub!("\n",'')
      html.gsub!("<div","\n<div")
      html.gsub!("<p","\n<p")
      html.gsub!("<br","\n<br")
      html.gsub!("\n\n","\n")

      html = ActionController::Base.helpers.strip_tags(html)
      html.gsub!(" \n","\n")
      html
    else
      raise "don't know how to generate format: #{format}"
    end
  end

  def generate_haml html, options
    html_file = Tempfile.new("#{Time.now.to_i.to_s}.html", "#{RAILS_ROOT}/tmp")
    html_file.write html
    html_file.close
    cmd = "html2haml #{html_file.path}"
    haml = `#{cmd}`
    html_file.delete

    format_haml(haml, @clauses_file)
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

  DIV = %w[ABillTo Abt1 Abt2 Abt3 Abt4
    Amendment Amendment_Number Amendment_Text Amendments_Commons Arrangement
    BillData BillTitle Bpara
    ClauseText ClauseTitle Clause_Committee
    Clauses ClausesToBeConsidered Clauses_ar
    Committee CommitteeShorttitle
    Cover CoverHeading CoverPara
    CrossHeadingSch CrossHeadingTitle
    Date
    Footer
    Given
    Head HeadAmd HeadConsider HeadNotice Head_thin
    Heading_ar Heading_text
    Jref
    List LongTitle Longtitle_text
    MarshalledOrderNote Motion Move
    NewClause_Committee NoticeOfAmds
    OrderAmendmentText OrderCrossHeading OrderHeading OrderPreamble OrderText
    Order_Committee Order_House Order_Motion
    Para_sch Prelim
    Report Resolution ResolutionHead ResolutionPreamble ResolutionText Rubric
    Schedule_Committee SchedulesTitle_ar Schedules_ar
    Shorttitle Stageheader SubSection
    Table Text_motion
    WordsOfEnactment].inject({}){|h,v| h[v]=true; h}

  DIV_RE = Regexp.new "(^#{DIV.keys.join("$|")}$)"

  TABLE = %w[TableData].inject({}){|h,v| h[v]=true; h}
  TABLE_RE = Regexp.new "(^#{TABLE.keys.join("$|")}$)"

  TR = %w[Row].inject({}){|h,v| h[v]=true; h}
  TR_RE = Regexp.new "(^#{TR.keys.join("$|")}$)"

  TH = %w[CellH].inject({}){|h,v| h[v]=true; h}
  TH_RE = Regexp.new "(^#{TH.keys.join("$|")}$)"

  TD = %w[Cell].inject({}){|h,v| h[v]=true; h}
  TD_RE = Regexp.new "(^#{TD.keys.join("$|")}$)"

  SPAN = %w[Amendment_Text_text
      Bold Bold_text
      ClauseTitle_text
      Date_text Day Definition Definition_text Dropcap
      Enact
      FrameData
      Italic
      Jref_text
      Letter Line Line_text ListItem List_text
      Move_text
      NoteTxt Notehead Number Number_text
      OrderDate OrderPara
      Page Page_text Para_sch_text Para_text PgfNumString Proposer_name
      ResolutionDate ResolutionHead_text ResolutionPara ResolutionPara_text
      ResolutionSubPara ResolutionSubPara_text ResolutionText_text
      STCommons STHouse STLords STText SmallCaps
      SubPara SubPara_sch SubSection_text SubSubPara_sch
      TextContinuation TextContinuation_text
      WHITESPACE ].inject({}){|h,v| h[v]=true; h}

  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"

  HR = %w[Separator_thick Separator_thin].inject({}){|h,v| h[v]=true; h}
  HR_RE = Regexp.new "(#{HR.keys.join("|")})"

  def doc_to_html(doc)
    @in_clauses = false
    @in_paragraph = false
    @in_hyperlink = false
    @para_line_anchor = nil
    node_children_to_html(doc.root)
  end

  def node_children_to_html(node)
    node.children.each do |child|
      node_to_html(child)
    end if node.children
  end

  def css_class node
    @last_css_class = node.name.gsub('.','_')
    @last_css_class += " #{node['class']}" unless node['class'].blank?
    @last_css_class
  end

  def add_html_element name, node
    start_tag = []
    start_tag << %Q|<#{name} class="#{css_class(node)}"|
    start_tag << %Q| id="#{node['id']}"| if node['id']
    if name == 'hr'
      start_tag << " />"
    else
      start_tag << ">"
    end

    add start_tag.join('')

    if name != 'hr'
      node_children_to_html(node)
      add "</#{name}>"
    end

    @in_para_line = false unless @last_css_class[/^(Bold|Italic|SmallCaps)$/]
  end

  def find_bill_url bill_name
    bill = Bill.from_name bill_name
    bill.parliament_url
  end

  def find_act_url act_name
    act = Act.from_name act_name
    act.opsi_url
  end

  def add_link_element node, div=false
    item = node.inner_text
    url = case item
      when /Act/
        find_act_url(item)
      when /Bill/
        find_bill_url(item)
      else
        ''
    end

    id = node['id'] ? %Q| id="#{node['id']}"| : ''
    if div
      add %Q|<div#{id} class="#{node.name}">|
      add %Q|<a href="#{url}">| unless url.blank?
    elsif url.blank?
      add %Q|<span#{id} class="#{node.name}">|
    else
      add %Q|<a#{id} href="#{url}" class="#{node.name}">|
    end
    @in_hyperlink = true
    node_children_to_html(node)
    @in_hyperlink = false
    add "</a>" unless url.blank?
    add "</div>" if div
    add "</span>" if url.blank? && !div

    if @para_line_anchor
      add @para_line_anchor
      @para_line_anchor = nil
    end
  end

  def handle_clauses node
    @in_clauses = true
    add_html_element 'div', node
  end

  def handle_clause node
    if node['HardReference'] && @in_clauses
      @clause_number = node.at('PgfNumString').inner_text.strip
    end
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
      if node.at('/text()').to_s.empty?
        end_tag = @html.pop
        add "&nbsp;"
        add end_tag
      end
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
    last_line = nil
    if @html.last && @html.last.include?('<span')
      last_line = @html.pop
    end

    line = node['LineNum'].to_s
    add %Q|<br />| if @in_para_line || @in_hyperlink
    anchor_name = "page#{@page_number}-line#{line}"
    para_line_anchor = %Q|<a name="#{anchor_name}"></a>|
    para_line_anchor += %Q|<a name="clause#{@clause_number}-#{anchor_name}"></a>| unless @clause_number.blank?

    # if last_line && last_line.include?('ClauseTitle_text')
      # puts "@in_hyperlink: #{@in_hyperlink}"
      # puts para_line_anchor
      # puts last_line
    # end

    if @in_hyperlink
      @para_line_anchor = para_line_anchor
    else
      add para_line_anchor
    end

    if last_line
      add last_line
    end
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

  def handle_amendment_reference node
    clause = node['Clause']
    schedule = node['Schedule']
    page = node['Page']
    line = node['Line']
    ref = ''
    ref += "clause#{clause}-" if clause
    ref += "schedule#{schedule}-" if schedule
    ref += "page#{page}-" if page
    ref += "line#{line}" if line
    ref.chomp!('-')

    add %Q|<a href="##{ref}" class="#{css_class(node)}">|
    node_children_to_html(node)
    add '</a>'
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
      when /BillTitle|Shorttitle/
        add_link_element node, true
      when 'ParaLineStart'
        handle_para_line_start node
      when 'Para'
        handle_para node
      when 'PageStart'
        handle_page_start node
      when 'Clauses'
        handle_clauses node
      when 'Clause'
        handle_clause node
      when 'Clause_ar'
        handle_clause_ar node
      when 'Clause_ar_text'
        handle_clause_ar_text node
      when 'AmendmentReference'
        handle_amendment_reference node
      when /_number$/
        add_html_element 'span', node
      when /^PgfNumString_\d+$/
        handle_pgf_num_string node
      when /_PgfTag$/
        handle_pdf_tag node
      when /^(SubPara_sch|SubSubPara_sch|ResolutionPara|)$/
        handle_sub_para_variants node
      when /^EndRule$/
        #ignore
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
      text = node.to_s.gsub("/n", "<br />")
      add text
      @in_para_line = true if !text.blank? && @last_css_class[/^(Bold|Italic|SmallCaps|.+_text)$/]
    end
  end
end