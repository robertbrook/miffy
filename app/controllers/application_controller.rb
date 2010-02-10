# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def serve_epub
    send_file "#{RAILS_ROOT}/public/Digital-Economy-Bill-HL.epub", :content_type => 'application/epub+zip'
  end
end
