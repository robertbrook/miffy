class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def index
    paths = Dir.glob(RAILS_ROOT + '/spec/fixtures/*.mif')
    @mif_files = MifFile.load(paths)
    @bill_names = @mif_files.collect(&:bill).collect{|x| x ? x.name : ''}.uniq.sort
    @files_by_bill = @mif_files.group_by{|x| x.bill ? x.bill.name : nil}
    @act_files = Dir.glob(RAILS_ROOT + '/spec/fixtures/Acts/*.xml')
    @title = "MIF Files"
    render :template => 'index.haml'
  end
  
  def convert
    file_name = URI.decode(params[:file])
    
    if File.exists?(file_name)
      params[:format] = params[:format] || 'html'
      mif_file = MifFile.find_by_path(file_name)
      mif_file = MifFile.new :path => file_name unless mif_file

      respond_to do |format|
        format.html do
          mif_file.convert_to_haml unless mif_file.haml_template_exists? && !params[:force]
          @title = mif_file.html_page_title
          template = mif_file.haml_template
          render :template => template          
        end
        format.text do
          render :text => mif_file.convert_to_text
        end
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

end
