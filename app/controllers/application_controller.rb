class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def index
    @files = Dir.glob(RAILS_ROOT + '/spec/fixtures/*.mif')
    render :template => 'index.haml'
  end
  
  def convert
    file_name = URI.decode(params[:file])
    @title = file_name
    
    if File.exists?(file_name)
      xml = MifParser.new.parse file_name
      haml = Mif2HtmlParser.new.parse_xml xml, :format => :haml, :body_only => true
      
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

end
