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
    render :template => 'index.haml'
  end
  
  def convert
    file_name = URI.decode(params[:file])
    
    if File.exists?(file_name)
      xml = MifParser.new.parse file_name
      haml = Mif2HtmlParser.new.parse_xml xml, :format => :haml, :body_only => true
      
      @title = page_title(file_name, xml)
      
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
    def helper
      Helper.instance
    end
  
    def page_title file_name, xml
      title = ''
      type = helper.document_type(file_name)
      display_type = type.sub('_', ' ').gsub(/\b\w/){$&.upcase}
      if display_type == 'Marshalled List'
        display_type << ' of Amendments'
      end

      if type == 'clauses' || type == 'cover' || type == 'arrangement'
        doc = Hpricot.XML xml.to_s
        doc_title = (doc/'BillData'/'BillTitle'/'text()').to_s
        title = doc_title + " (#{display_type})"
      elsif type == 'amendment_paper' || type == 'marshalled_list'
        doc = Hpricot.XML xml.to_s
        doc_title = (doc/'CommitteeShorttitle'/'STText'/'text()').to_s
        title = doc_title + " (#{display_type})"
      else
        title = display_type
      end
      title
    end
end
