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
    puts filename
    unless filename
      render :status => 404
    else
      file = RAILS_ROOT + "/public/epub/#{filename}.epub"
      unless File.exists?(file)
        render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404
      else
        send_file "#{file}", :content_type => 'application/epub+zip'
      end
    end
  end
end
