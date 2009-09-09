require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ExplanatoryNote do

  describe 'when create html note text' do
    before(:all) do
      @note = ExplanatoryNote.new :note_text => '  Clause 1 ' + '
7. Under section 6(1) of the Railways Act 2005 (“the 2005 Act”) the Secretary of State
has the power to “provide, or agree to provide, financial assistance to any person –
 ' + '
(a) for the purpose of securing the provision, improvement or development of railway
services or railway assets; or

(b) for any other purpose relating to a railway or to railway services.”
'
      @html = @note.html_note_text
    end

    it 'should wrap Clause heading in clause_title span' do
      @html.should include('<span class="NoteClauseTitle">Clause 1</span>')
    end

    it 'should paragraphs in p elements' do
      @html.should include('<p>(a) for the purpose of securing the provision, improvement or development of railway services or railway assets; or</p>')

      @html.should include('<p>(b) for any other purpose relating to a railway or to railway services.”</p>')

      @html.should include('<p>7. Under section 6(1) of the Railways Act 2005 (“the 2005 Act”) the Secretary of State has the power to “provide, or agree to provide, financial assistance to any person –</p>')
    end
  end

end