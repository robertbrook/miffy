class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def index
    paths = Dir.glob(RAILS_ROOT + '/spec/fixtures/*.mif').select {|x| !x[/Book.mif$/]}
    paths << (RAILS_ROOT + '/spec/fixtures/Finance_Clauses.xml')
    paths << (RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelClauses.mif')
    paths << (RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelLordsClauses.mif')
    paths << (RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelLordsInboundClauses.mif')
    paths << (RAILS_ROOT + '/spec/fixtures/finance/2R printed/Clauses.mif')
    paths << (RAILS_ROOT + '/spec/fixtures/finance/2R printed/Schedules.mif')

    paths += Dir.glob(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/*.mif').select {|x| !x[/Book.mif$/]}

    en_paths = []
    en_paths << (RAILS_ROOT + '/spec/fixtures/ChannelTunnel/ChannelTunnelENs.pdf')
    en_paths << (RAILS_ROOT + '/spec/fixtures/DigitalEconomy/ens/DigitalEconomy Bill.pdf')

    @clickable_file_types = '|Amendments|Clauses|Schedules|Marshalled List|Tabled Amendments|Tabled Report|Report|Arrangement|'

    @mif_files = MifFile.load(paths)
    @en_files = ExplanatoryNotesFile.load(en_paths)
    Effect.load(RAILS_ROOT + '/spec/fixtures/DigitalEconomy/effects/Digital Economy Bill Table of Effects.csv')

    @bill_names = @mif_files.collect(&:bill).collect{|x| x ? x.name : ''}.uniq.sort
    @files_by_bill = @mif_files.group_by{|x| x.bill ? x.bill.name : nil}
    @act_files = Dir.glob(RAILS_ROOT + '/spec/fixtures/Acts/*.xml')
    @title = "Miffy"
    render :template => 'index.haml'
  end

  def convert
    file_name = params[:file]
    if file_name && File.exists?(file_name = URI.decode(file_name))
      params[:format] = params[:format] || 'html'
      mif_file = MifFile.find_by_path(file_name)

      if mif_file
        respond_to do |format|
          format.html do
            options = {:interleave_notes => params[:interleave], :force => params[:force], :effects => params[:effects]}
            template = mif_file.convert_to_haml(options)
            @mif_file = mif_file
            @title = mif_file.html_page_title
            @show_interleave_link = mif_file.has_explanatory_notes? && !params[:interleave] && !params[:effects]
            @show_uninterleave_link = mif_file.has_explanatory_notes? && params[:interleave]
            render :template => template
          end
          format.text do
            render :text => mif_file.convert_to_text
          end
        end
      else
        render_not_found
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
    render :template => 'public/404.html', :status => 404, :layout => false
  end

end
