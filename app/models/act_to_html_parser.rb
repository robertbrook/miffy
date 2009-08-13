require 'htmlentities'
require 'open-uri'
require 'hpricot'

class ActToHtmlParser
  
  # e.g. parser.parse_xml_file("LawCommissionsAct.xml")
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
      @html = ['<div id="Legislation">']
      doc_to_html(doc)
      add ['</div>']
    else
      @html = ['<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body><div id="Legislation">']
      doc_to_html(doc)
      add ['</div></body></html>'] 
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
  
  DIV = %w[LongTitle DateOfEnactment
      P1group 
      P1para
      P2
      P2para
      P3
      P3para
      Number
      LongTitle
      Text].inject({}){|h,v| h[v]=true; h}
  DIV_RE = Regexp.new "(^#{DIV.keys.join("$|")}$)"

  SPAN = %w[DateText Addition
      CommentaryRef
      Term ].inject({}){|h,v| h[v]=true; h}
  SPAN_RE = Regexp.new "(^#{SPAN.keys.join("$|")}$)"

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  UL_RE = Regexp.new "(#{UL.keys.join("|")})"
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}
  LI_RE = Regexp.new "(#{LI.keys.join("|")})"
  
  def doc_to_html(doc)
    @in_prelims = false
    @in_body= false
    @last_element_P1 = false
    @clause_title = ""
    node_children_to_html(doc.root)
  end
  
  def node_children_to_html(node)
    node.children.each do |child|
      node_to_html(child)
    end if node.children
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
  end
  
  def css_class node
    @last_css_class = node.name.gsub('.','_')
    @last_css_class += " #{node['class']}" unless node['class'].blank?
    @last_css_class
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
      when 'Primary'
        node_children_to_html(node)
      when 'PrimaryPrelims'
        @in_prelims = true
        add_html_element('div', node)
      when 'Body'
        @in_prelims = false
        @in_body = true
        node_children_to_html(node)
      when 'Title'
        if @in_prelims
          add_html_element('h1', node)
        elsif @in_body
          @clause_title = node.children[0].to_s
        end
      when 'P1'
        @last_element_P1 = true
        add_html_element('div', node)
      when 'Pnumber'
        if @last_element_P1
          add %Q|<div class="P1Title">|
          add %Q|<div class="TitleNum">#{node.children[0].to_s}</div>|
          add %Q|<div class="Title">#{@clause_title}</div>|
          add "</div>"
          @last_element_P1 = false
          @clause_title = ""
        else
          add %Q|<div class="Pnumber">(#{node.children[0].to_s})</div>|
        end
      when /^ukm:/
        #ignore metadata for now
      when 'Commentaries'
        #ignore for now
      when DIV_RE
        add_html_element 'div', node
      when SPAN_RE
        add_html_element 'span', node
      else
        raise node.name
        node_children_to_html(node)
    end if node.elem?
    
    if node.text?
      text = node.to_s.gsub("/n", "<br />")
      if @in_prelims
        text.gsub!(" c. ", " Chapter ")
      end
      add text
    end
  end
end