class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  class Helper
    include Singleton
    include ApplicationHelper
  end

  def index
    @files = Dir.glob(RAILS_ROOT + '/spec/fixtures/*.mif')
    @act_files = Dir.glob(RAILS_ROOT + '/spec/fixtures/Acts/*.xml')
    render :template => 'index.haml'
  end
  
  def convert
    file_name = URI.decode(params[:file])
    template_format = (params[:format] || :haml).to_sym
    
    if File.exists?(file_name)
      xml = MifParser.new.parse file_name
      result = MifToHtmlParser.new.parse_xml xml, :format => template_format, :body_only => true
      
      params[:format] = params[:format] || 'html'
      respond_to do |format|
        format.html { render_html(file_name, xml, result) }
        format.text { render :text => result }
      end
    else
      render_not_found 
    end
  end

  def act
    file_name = URI.decode(params[:file])
    
    if File.exists?(file_name)
      haml = ActToHtmlParser.new.parse_xml_file file_name, :format => :haml, :body_only => true
      
      @title = 'test'
      
      results_dir = RAILS_ROOT + '/app/views/results'
      Dir.mkdir results_dir unless File.exist?(results_dir)
      template = "#{results_dir}/#{file_name.gsub('/','_').gsub('.','_')}.haml"
      
      File.open(template,'w+') {|f| f.write(haml) }
      
      render :template => template
    else
      render_not_found
    end
  end

  def render_not_found
    render :template => 'public/404.html', :status => 404
  end

  private
  
    def render_html file_name, xml, result
      @title = page_title(file_name, xml)
      
      results_dir = RAILS_ROOT + '/app/views/results'
      Dir.mkdir results_dir unless File.exist?(results_dir)
      template = "#{results_dir}/#{file_name.gsub('/','_').gsub('.','_')}.haml"
      
      File.open(template,'w+') {|f| f.write(result) }
        
      render :template => template
    end

    def helper
      Helper.instance
    end
  
    def text_item xml, xpath
      doc = Hpricot.XML xml.to_s
      (doc/xpath).to_s
    end
    
    def make_title xml, display_type, xpath
      text_item(xml, 'BillData/BillTitle/text()') + " (#{display_type})"
    end
    
    def page_title file_name, xml
      type = helper.document_type(file_name)
      display_type = type.sub('_', ' ').gsub(/\b\w/){$&.upcase}
      if display_type == 'Marshalled List'
        display_type << ' of Amendments'
      elsif display_type == 'Consideration'
        display_type << ' of Bill'
      end

      case type
        when /^(clauses|cover|arrangement)$/
          make_title xml, display_type, 'BillData/BillTitle/text()'
        when /^(amendment_paper|marshalled_list)$/
          make_title xml, display_type, 'CommitteeShorttitle/STText/text()'
        when 'consideration'
          make_title xml, display_type, 'Head/HeadAmd/Shorttitle/text()'
        else
          display_type
      end      
    end
end
