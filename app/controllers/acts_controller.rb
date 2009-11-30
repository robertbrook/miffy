class ActsController < ApplicationController

  def index
    @acts = Act.all(:order => 'name')
    render :index
  end

  def show
    @act = Act.find(params[:id], :include => 'act_sections')
    @sections = @act.act_sections
  end

end
