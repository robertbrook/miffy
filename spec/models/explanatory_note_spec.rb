require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ExplanatoryNote do

  describe 'when asked for html note text' do

    describe 'and clause title includes title name' do
      before(:all) do
        @note = ExplanatoryNote.new :note_text => '  Clause 3: Royal Mail Companies to be publicly owned
        27.     Subsection (1) requires that each Royal Mail company must be publicly owned. To ensure that
        this is the case, subsection (2)(a) and (b) provide that any issue or transfer of shares or of share
        rights in a company is ineffective if it would cause a Royal Mail company to cease to be publicly owned.
        The meaning of Royal Mail company is set out in clause 4.
        Clauses 10 to 12 contain further details as to what is meant by “publicly owned”. '
        @html = @note.html_note_text
      end

      it 'should wrap Clause heading in clause_title span' do
        @html.should include('<span class="NoteClauseTitle">Clause 3: Royal Mail Companies to be publicly owned</span>')
      end

      it 'should wrap paragraph in p element' do
        @html.should include('<p>27.     Subsection (1) requires that each Royal Mail company must be publicly owned. To ensure that this is the case, subsection (2)(a) and (b) provide that any issue or transfer of shares or of share rights in a company is ineffective if it would cause a Royal Mail company to cease to be publicly owned. The meaning of Royal Mail company is set out in clause 4. Clauses 10 to 12 contain further details as to what is meant by “publicly owned”.</p>')
      end
    end

    describe 'and clause title does not include title name' do
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

      it 'should wrap paragraphs in p elements' do
        @html.should include('<p>(a) for the purpose of securing the provision, improvement or development of railway services or railway assets; or</p>')

        @html.should include('<p>(b) for any other purpose relating to a railway or to railway services.”</p>')

        @html.should include('<p>7. Under section 6(1) of the Railways Act 2005 (“the 2005 Act”) the Secretary of State has the power to “provide, or agree to provide, financial assistance to any person –</p>')
      end
    end
  end

end