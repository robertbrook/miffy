class ApiController < ApplicationController
  def index
  end
  
  def clause_note
    @error = nil
    @clause_text = ""
    
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
        end
      end
    end
    
    respond_to do |format|
      format.xml  { render :layout => false }
      format.json { render :json => results_to_json(@clause_text, @error) }
      format.js   { render :json => results_to_json(@clause_text, @error) }
      format.text { render :text => results_to_text(@clause_text, @error) }
      format.csv  { render :text => results_to_csv(@clause_text, @error) }
      format.yaml { render :text => results_to_yaml(@clause_text, @error) }
    end
  end
  
  private
    def results_to_json message, error
      if error
        note_text = error
      else
        note_text = message
      end
      %Q|{"clause_note": { "clause_text": "#{note_text}"}} |
    end
    
    def results_to_text message, error
      if error
        note_text = error
      else
        note_text = message
      end
      "\n\n  - " + note_text.gsub("\n", "\n\    ")
    end
    
    def results_to_yaml message, error
      "---\n#{results_to_text(message, error)}"
    end
 
    def results_to_csv message, error
      if error
        note_text = error
      else
        note_text = message
      end
      "clause_note\n#{note_text}\n"
    end
    
end
