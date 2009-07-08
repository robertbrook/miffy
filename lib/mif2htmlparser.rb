require 'mifparser'
require 'htmlentities'

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
      NewClause_Committee Order_House
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
      Move
      SubSection].inject({}){|h,v| h[v]=true; h}
  DIV_RE = Regexp.new "(^#{DIV.keys.join("$|")}$)"

  # P = %w[].inject({}){|h,v| h[v]=true; h}

  SPAN = %w[ResolutionPara ResolutionSubPara
      Para SubPara_sch
      SubSubPara_sch
      Definition
      TextContinuation
      PgfNumString
      OrderDate
      ResolutionDate
      OrderPara
      Day Date_text STText Notehead NoteTxt
      Number Page Line ].inject({}){|h,v| h[v]=true; h}
  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"

  HR = %w[Separator_thick].inject({}){|h,v| h[v]=true; h}

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
    xml << %Q|<#{name} class="#{node.name.gsub('.','_')}"|
    xml << %Q| id="#{node['id']}"| if node['id']
    xml << ">"
    node_children_to_html(node, xml)
    xml << "</#{name}>"
  end

  def node_to_html(node, xml)
    case node.name.gsub('.','_')
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
      when /^(SubPara_sch|SubSubPara_sch)$/
        already_in_paragraph = @in_paragraph
        tag = (already_in_paragraph ? 'span' : 'p')
        @in_paragraph = true
        add_html_element(tag, node, xml)
        @in_paragraph = false unless already_in_paragraph
      when DIV_RE
        add_html_element 'div', node, xml
      when SPAN_RE
        add_html_element 'span', node, xml
      when UL_RE
        add_html_element 'ul', node, xml
      when LI_RE
        add_html_element 'li', node, xml
      else
        node_children_to_html(node, xml)
    end if node.elem?

    if node.text?
      xml << node.to_s
    end
  end

end