class ActsController < ApplicationController

  def index
    @acts = Act.all
    render :index, :layout => false
  end

end
