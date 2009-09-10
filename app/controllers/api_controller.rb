class ApiController < ApplicationController
  def index
  end
  
  def clause_note
    @error = nil
    @clause_text = ""
    @clause_html = ""
    
    bill_id = params[:bill_id]
    clause_num = params[:clause]
    format = params[:format]
    
    unless bill_id && clause_num
      @error = "You need to supply a bill id and a clause number"
    else
      bill = Bill.find_by_id(bill_id)
      unless bill
        @error = "Bill not found"
      else
        clause = bill.note_by_clauses.find_by_clause_number(clause_num)
        unless clause
          @error = "Clause not found"
        else
          @clause_text = clause.note_text
          @clause_html = clause.html_note_text
        end
      end
    end
    
    respond_to do |format|
      format.html { render }
      format.xml  { render :layout => false }
      format.json { render :json => note_to_json(@clause_text, @error) }
      format.js   { render :json => note_to_json(@clause_text, @error) }
      format.text { render :text => note_to_text(@clause_text, @error) }
      format.csv  { render :text => note_to_csv(@clause_text, @error) }
      format.yaml { render :text => note_to_yaml(@clause_text, @error) }
    end
  end
  
  def schedule_note
    @error = nil
    @schedule_text = ""
    @schedule_html = ""
    
    bill_id = params[:bill_id]
    schedule_num = params[:schedule]
    format = params[:format]
    
    unless bill_id && schedule_num
      @error = "You need to supply a bill id and a schedule number"
    else
      bill = Bill.find_by_id(bill_id)
      unless bill
        @error = "Bill not found"
      else
        schedule = bill.note_by_schedules.find_by_schedule_number(schedule_num)
        unless schedule
          @error = "Schedule not found"
        else
          @schedule_text = schedule.note_text
          @schedule_html = schedule.html_note_text
        end
      end
    end
    
    respond_to do |format|
      format.html { render }
      format.xml  { render :layout => false }
      format.json { render :json => note_to_json(@schedule_text, @error) }
      format.js   { render :json => note_to_json(@schedule_text, @error) }
      format.text { render :text => note_to_text(@schedule_text, @error) }
      format.csv  { render :text => note_to_csv(@schedule_text, @error) }
      format.yaml { render :text => note_to_yaml(@schedule_text, @error) }
    end
  end
  
  private
    def note_to_json message, error
      if error
        note_text = error
      else
        note_text = message
      end
      %Q|{"explanatory_note": { "note_text": "#{note_text}"}} |
    end
    
    def note_to_text message, error
      if error
        note_text = error
      else
        note_text = message
      end
      note_text
    end
    
    def note_to_yaml message, error
      text = "\n\n  - " + note_to_text(message, error).gsub("\n", "\n\    ")
      "---\n#{text}"
    end
 
    def note_to_csv message, error
      if error
        note_text = error
      else
        note_text = message
      end
      "explanatory_note\n#{note_text}\n"
    end
    
end
