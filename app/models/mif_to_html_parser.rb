require 'mifparserutils'
require 'htmlentities'
require 'open-uri'
require 'hpricot'
require 'mechanize'

class MifToHtmlParser

  include MifParserUtils

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    unless options.has_key?(:clauses_file)
      options.merge!({:clauses_file => File.dirname(xml_file)+'/Clauses.mif' })
    end
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
      File.open("#{RAILS_ROOT}/tmp/example.html", 'w+') {|f| f.write(html) } if RAILS_ENV == 'development'
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

    # File.open('/Users/x/example.haml', 'w+') {|f| f.write(haml)}
    format_haml(haml, @clauses_file)
  end

  def generate_html doc, options
    @interleave = options[:interleave_notes]

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
    AsAm
    BillData BillTitle Bpara
    CenteredHeading Chapter
    ClauseText ClauseTitle Clause_Committee
    Clauses ClausesToBeConsidered Clauses_ar
    Committee CommitteeShorttitle ChapterTitle
    Cover CoverHeading
    CrossHeading CrossHeadingSch CrossHeadingTitle CrossHeadingTitle_ar
    Date
    Definition DefinitionListItem
    Enda Endb
    Endorse
    Footer
    Given
    Head HeadAmd HeadConsider HeadNotice Head_thin
    Heading_ar Heading_text
    List ListItem
    LongTitle Longtitle_text
    MarshalledOrderNote Motion Move
    NewClause_Committee NoticeOfAmds
    OrderAmendmentText OrderCrossHeading
    OrderHeading
    OrderPreamble OrderText
    Order_Committee Order_House Order_Motion
    Part Part_ar PartSch PartTitle
    Prelim
    Report Resolution ResolutionHead
    ResolutionPreamble ResolutionText Rubric
    Schedule_ar
    Schedules SchedulesTitle
    Schedule_Committee SchedulesTitle_ar Schedules_ar
    ScheduleTitle Schedule
    SectionReference
    Shorttitle Stageheader SubSection
    Split
    TableTitle
    Table Text_motion TextContinuation
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
      ActClauseTitle_text
      BillReference
      ClauseTitle_text
      Date_text Day Definition_text Dropcap
      Enact Sbscript
      FrameData Formula
      Italic
      Letter Line Line_text List_text
      Move_text
      NoteTxt Notehead Number Number_text
      Page Page_text Para_sch_text Para_text PartNumber_ar PartNumber_ar_text
      PartTitle_ar
      PgfNumString Proposer_name
      ResolutionDate ResolutionHead_text ResolutionPara_text
      ResolutionSubPara_text ResolutionText_text
      Roman Roman_text
      ScheduleNumber_ar ScheduleNumber_ar_text
      ScheduleTitle_ar ScheduleTitle_ar_text ScheduleTitle_text
      STCommons STHouse STLords STText SmallCaps
      Superscript Superscript_text SmallCaps_text
      SubSection_text
      WHITESPACE ].inject({}){|h,v| h[v]=true; h}

  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  IGNORE = %w[Jref_text
      InternalReference InternalReference_text
      Interpretation FileType
      Jref ].inject({}){|h,v| h[v]=true; h}

  IGNORE_RE = Regexp.new "(^#{IGNORE.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"

  HR = %w[Separator_thick Separator_thin].inject({}){|h,v| h[v]=true; h}
  HR_RE = Regexp.new "(#{HR.keys.join("|")})"

  def doc_to_html(doc)
    @in_clauses = false
    @in_schedules = false
    @in_paragraph = false
    @in_amendment = false
    @in_hyperlink = false
    @para_line_anchor = nil
    @pages_rendered = 0
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

  def a_attribute node, attribute
    node[attribute] ? " #{attribute}='#{node[attribute]}'" : ''
  end

  def add_anchor node
    tag = []
    tag << '<a'
    tag << a_attribute(node, 'rel')
    tag << a_attribute(node, 'resource')
    tag << a_attribute(node, 'href')
    tag << a_attribute(node, 'title')
    tag << '>'
    add tag.join('')
    @in_hyperlink = true
    node_children_to_html(node)
    @in_hyperlink = false
    add '</a>'

    add_trailing_para_line_anchor
  end

  def add_html_element name, node
    tag = []
    tag << %Q|<#{name} class="#{css_class(node)}"|
    tag << %Q| id="#{node['id']}"| if node['id']
    tag << %Q| colspan="#{node['colspan']}"| if node['colspan']
    if name == 'hr'
      tag << " />"
    else
      tag << ">"
    end

    add tag.join('')

    if name != 'hr'
      if @in_amendment && node['anchor']
        add %Q|<a name="#{node['anchor']}"/>|
      end
      node_children_to_html(node)
      add "</#{name}>"
    end

    @in_para_line = false unless @last_css_class[/^(Bold|Italic|SmallCaps)$/]
  end

  def find_bill_url bill_name
    bill_name = bill_name.chomp(' [HL]')
    @bill = Bill.from_name bill_name
    @bill.parliament_url
  end

  def find_act_url act_name
    act = Act.from_name act_name
    act.statutelaw_url ? act.statutelaw_url : act.opsi_url
  end

  def add_xref_link node
    if node['anchor-ref']
      id = get_id_attr node
      add %Q|<a#{id} class="#{node.name}" href="##{node['anchor-ref']}">|
      @in_hyperlink = true
      node_children_to_html(node)
      @in_hyperlink = false
      add "</a>"
    else
      add_html_element 'span', node
    end
  end

  def get_id_attr node
    id = node['id'] ? %Q| id="#{node['id']}"| : ''
  end

  def add_link_element node, div=false
    id = get_id_attr node
    item = node.inner_text
    url = case item
      when /Act/
        find_act_url(item)
      when /Bill/
        find_bill_url(item)
      else
        ''
    end

    title = node.inner_text.blank? ? '' : %Q| title="#{node.inner_text}"|

    if div
      add %Q|<div#{id} class="#{node.name}">|
      add %Q|<a href="#{url}"#{title}>| unless url.blank?
    elsif url.blank?
      add %Q|<span#{id} class="#{node.name}">|
    else
      add %Q|<a#{id} href="#{url}" class="#{node.name}"#{title}>|
    end
    @in_hyperlink = true
    node_children_to_html(node)
    @in_hyperlink = false
    add "</a>" unless url.blank?
    add "</div>" if div
    add "</span>" if url.blank? && !div

    add_trailing_para_line_anchor
  end

  def add_trailing_para_line_anchor
    if @para_line_anchor
      add @para_line_anchor
      add "&nbsp;"
      @para_line_anchor = nil
    end
  end

  def handle_clauses node
    @in_clauses = true
    add_html_element 'div', node
  end

  def handle_schedules node
    @in_schedules = true
    add_html_element 'div', node
  end

  def find_clause_explanatory_note
    @interleave && (note = @bill.find_note_for_clause_number(@clause_number))
  end

  def find_schedule_explanatory_note
    @interleave && (note = @bill.find_note_for_schedule_number(@schedule_number))
  end

  def handle_clause node
    if node['HardReference'] && @in_clauses
      @clause_number = node.at('PgfNumString').inner_text.strip
    end
    clause_id = node['HardReference'].to_s.strip.gsub("&",'_')

    @in_amendment = false
    parent = node.parent
    while !@in_amendment && parent
      @in_amendment = true if parent.name == 'Amendment'
      parent = parent.parent
    end

    unless (@clause_number.blank? || clause_id.blank?) || @in_amendment
      clause_name = "clause#{@clause_number}"
      @clause_anchor_start = %Q|<a id="clause_#{clause_id}" name="#{clause_name}" href="##{clause_name}">|

      @explanatory_note = find_clause_explanatory_note unless @in_amendment

      add %Q|<div class="#{css_class(node)}" id="#{node['id']}">|
      node_children_to_html(node)
      if @explanatory_note && !@in_amendment
        add %Q|<div class="explanatory_note"><div class="explanatory_note_text"><span class="en_header">Explanatory Note:</span>#{@explanatory_note.html_note_text}</div></div>|
        add "</div>"
      end

      add "</div>"

      @explanatory_note = nil unless @in_amendment
    else
      add_html_element 'div', node
    end

    @in_amendment = false
  end

  def handle_clause_text node
    if @explanatory_note && !@in_amendment
      add %Q|<div class="ClauseTextWithExplanatoryNote" id="#{node['id']}en">|
    end
    add_html_element 'div', node
  end

  def handle_schedule node
    if node.at('ScheduleNumber_PgfTag') && @in_schedules
      @schedule_number = node.at('ScheduleNumber_PgfTag/PgfNumString/PgfNumString_0').inner_text.gsub('Schedule ', '').strip
    end
    if node['HardReference']
      schedule_id = node['HardReference'].to_s.strip.gsub("&",'_')
    end

    @in_amendment = (node.parent.name == 'Amendment') || (node.parent.parent.name == 'Amendment')

    unless (@schedule_number.blank? || schedule_id.blank?) || @in_amendment
      schedule_name = "schedule#{@schedule_number}"
      @schedule_anchor_start = %Q|<a id="schedule_#{schedule_id}" name="#{schedule_name}" href="##{schedule_name}">|

      @explanatory_note = find_schedule_explanatory_note unless @in_amendment

      add %Q|<div class="#{css_class(node)}" id="#{node['id']}">|
      node_children_to_html(node)
      if @explanatory_note && !@in_amendment
        add %Q|<div class="explanatory_note"><div class="explanatory_note_text"><span class="en_header">Explanatory Note:</span>#{@explanatory_note.html_note_text}</div></div>|
        add "</div>"
      end

      add "</div>"

      @explanatory_note = nil unless @in_amendment
    else
      add_html_element 'div', node
    end

    @in_amendment = false
  end

  def handle_schedule_text node
    if @explanatory_note && !@in_amendment
      add %Q|<div class="ScheduleTextWithExplanatoryNote" id="#{node['id']}_en">|
    end
    add_html_element 'div', node
  end

  def handle_pgf_num_string node
    if @clause_anchor_start
      add %Q|<span class="#{css_class(node)}">|
      add @clause_anchor_start
      node_children_to_html(node)
      add '</a>'
      add %Q|</span>|
      @clause_anchor_start = nil
    elsif @schedule_anchor_start
      add %Q|<span class="#{css_class(node)}">|
      add @schedule_anchor_start
      node_children_to_html(node)
      add '</a>'
      add %Q|</span>|
      @schedule_anchor_start = nil
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
    if css_class(node)[/_PgfTag/] && tag == 'span'
      raise "expecting #{css_class(node)} to be a paragraph but: already_in_paragraph -> #{already_in_paragraph} + #{node.inspect}"
    end
    @in_paragraph = true
    add_html_element(tag, node)
    @in_paragraph = false unless already_in_paragraph
  end

  def handle_para node
    already_in_paragraph = @in_paragraph
    tag = (already_in_paragraph ? 'span' : 'div')
    add_html_element(tag, node)
    already_in_paragraph
  end

  def handle_para_line_start node
    last_line = nil
    if @html.last && @html.last.include?('<span')
      last_line = @html.pop
    end

    first_line = false
    if @html.last && @html.last.strip == ''
      @html.pop
    end
    if @html.last && @html.last.include?('<')
      first_line = true
    end

    line = node['LineNum'].to_s
    add %Q|<br />| unless first_line
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
      if @pages_rendered == 0
        start_tag = @html.pop
        start_tag.gsub!("PageStart", "PageStart first")
        add start_tag
        @pages_rendered += 1
      end
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

  def handle_clause_ar node
    @clause_ref = node['HardReference']
    add_html_element 'div', node
  end

  def handle_clause_ar_text node
    add_html_element 'span', node

    end_tag = @html.pop
    last_line = @html.pop

    add %Q|<a href="convert?file=#{@clauses_file}#clause_#{@clause_ref}">|
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
      @html.pop if text.is_a?(String) && text[/^(;|\.|\))/] && @html.last == '&nbsp;'
      @html << text
    end
  end

  def node_to_html(node)
    case node.name.gsub('.','_')
      when 'Citation'
        add_link_element node
      when 'Xref'
        add_xref_link node
      when /BillTitle|Shorttitle/
        add_link_element node, true
      when 'ParaLineStart'
        handle_para_line_start node
      when 'PageStart'
        handle_page_start node
      when 'Clauses'
        handle_clauses node
      when 'Schedules'
        handle_schedules node
      when 'Clause'
        handle_clause node
      when 'Schedule'
        handle_schedule node
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
      when /^(Para|(Sub)+Para|Para_sch|(Sub)+Para_sch|ResolutionPara|ResolutionSubPara|CoverPara|OrderDate|OrderPara|OrderSubPara|OrderSubSubPara|OrderHousePara|OrderHouseSubPara|OrderHouseSubSubPara|RunIntoPara)$/
        handle_para node
      when /^EndRule$/
        #ignore
      when 'ClauseText'
        handle_clause_text node
      when 'ScheduleText'
        handle_schedule_text node
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
      when 'a'
        add_anchor node
      when IGNORE_RE
        # ignore for now
      else
        raise "don't know how to handle: #{node.name}"
        node_children_to_html(node)
    end if node.elem?

    if node.text?
      text = node.to_s
      text.gsub!("/n", "<br />")
      text.gsub!('&amp;','&')
      text.gsub!('&','&amp;')
      add text
      @in_para_line = true if !text.blank? && @last_css_class[/^(Bold|Italic|SmallCaps|.+_text)$/]
    end
  end
end