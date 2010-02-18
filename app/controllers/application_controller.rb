# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def serve_epub
    #send_file "#{RAILS_ROOT}/public/Digital-Economy-Bill-HL.epub", :content_type => 'application/epub+zip'
    filename = params[:filename]
    if filename
      file = RAILS_ROOT + "/public/#{filename}.epub"
    else
      file = ""
    end
    if File.exists?(file)
      send_file "#{file}", :content_type => 'application/epub+zip'
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404
    end
  end
end
