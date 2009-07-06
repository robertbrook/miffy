require 'mifparser'

class Mif2HtmlParser

  include MifParserUtils

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    parse_xml(IO.read(xml_file), options)
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    xml = [options[:html] ? '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>' : '<Document>']

    if options[:html]
      doc_to_html(doc, xml)
    else
      flows = (doc/'TextFlow')
      flows.each do |flow|
        unless is_instructions?(flow)
          handle_flow(flow, xml)
        end
      end
    end

    xml << [options[:html] ? '</body></html>' : '</Document>']
    xml = xml.join('')
    begin
      doc = REXML::Document.new(xml)
    rescue Exception => e
      puts e.to_s
    end

    if options[:indent]
      indented = ''
      doc.write(indented,2)
      indented
    else
      xml
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
      Committee Clause_Committee Order_Committee
      CrossHeadingSch Amendment
      NewClause_Committee Order_House].inject({}){|h,v| h[v]=true; h}
  DIV_RE = Regexp.new "(^#{DIV.keys.join("$|")}$)"

  # P = %w[].inject({}){|h,v| h[v]=true; h}

  SPAN = %w[Stageheader CommitteeShorttitle ClausesToBeConsidered
      MarshalledOrderNote SubSection Schedule_Committee
      Para Para_sch SubPara_sch SubSubPara_sch
      Definition
      CrossHeadingTitle Heading_text
      ClauseTitle ClauseText Move TextContinuation
      PgfNumString
      OrderDate OrderPreamble OrderText OrderPara
      Order_Motion OrderHeading
      OrderAmendmentText
      ResolutionPreamble
      Day Date_text STText Notehead NoteTxt
      Amendment_Text Amendment_Number Number Page Line ].inject({}){|h,v| h[v]=true; h}
  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"

  HR = %w[Separator.thick].inject({}){|h,v| h[v]=true; h}

  def doc_to_html(doc, xml)
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
      when /_PgfTag$/
        add_html_element 'p', node, xml
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