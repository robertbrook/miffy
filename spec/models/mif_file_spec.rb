require File.dirname(__FILE__) + '/../spec_helper.rb'

describe MifFile do
  
  describe 'when parsing bill titles' do
    it 'should find file names and titles' do
      titles = "030703fines_cc(j-refs_resolved).mif-   <String `Courts Bill'>
                030703fines_cc(j-refs_unresolved).backup.mif-   <String `Courts Bill'>
                030703fines_cc(j-refs_unresolved).mif-   <String `Courts Bill'>
                999999999.mif-   <String `Courts Bill'>
                CommA20031218DummyFM7.mif-   <String `Child Trust Funds Bill'>
                CommA20031229DummyFM7.mif-   <String `Child Trust Funds Bill'>
                CommA20040105DummyFM7.mif-   <String `Child Trust Funds Bill'>
                New clauses 1 & 2.mif-   <String `Finance Bill, as amended'>
                Report.backup.mif-   <String `LEGAL DEPOSIT LIBRARIES BILL'>
                Report.mif-   <String `LEGAL DEPOSIT LIBRARIES BILL'>
                Sch 1.mif-   <String `finance Bill'>
                Tabled 27 June.mif-   <String `Finance Bill'>
                Tabled 4 June (SCB).mif-   <String `FINANCE BILL'>
                Tabled 6 June (SCB).mif-   <String `FINANCE BILL'>
                Tabling19thJune_cc.backup.mif-   <String `Courts Bill'>
                Tabling19thJune_cc.mif-   <String `Courts Bill'>
                Tabling3rdJuly_cc.mif-   <String `Courts Bill'>
                amsorig.mif-   <String `Finance Bill, as amended'>
                amts201repfinal1.mif-   <String `Finance Bill'>
                ccam4.mif-   <String `Health and Social Care (Community Health and Standards) Bill'>
                cr2.mif-   <String `Anti-social Behaviour Bill'>
                fiream2.mif-   <String `fireworks BilL'>
                test.mif-   <String `Communications Bill'>
                testnumbers.mif-   <String `Courts Bill'>
                Arrangement.mif-      <AttrValue `Law Commission [HL]'>
                Clauses.mif-      <AttrValue `Law Commission [HL]'>
                Cover.mif-      <AttrValue `Law Commission [HL]'>
                pbc0850206m.mif-   <String `Equality Bill'>
                pbc0900206m.mif-   <String `Finance Bill'>
                pbc0930106a.mif-   <String `Local Democracy, Economic Development and '>
                pbc0930106a.mif-   <String `Construction Bill'>"
      
      results = []
      MifFile.parse_bill_titles(titles,'/home/x') do |file, title|
        results << [file, title]
      end
      
      results.size.should == 31
      results.first.should == ['/home/x/030703fines_cc(j-refs_resolved).mif', 'Courts Bill']
      results[8].should ==    ['/home/x/Report.backup.mif', 'Legal Deposit Libraries Bill']
      results[17].should ==   ['/home/x/amsorig.mif', 'Finance Bill']
      results[21].should ==     ['/home/x/fiream2.mif', 'Fireworks Bill']
      results[26].should ==  ['/home/x/Cover.mif', 'Law Commission [HL]']
      results[29].should ==  ['/home/x/pbc0930106a.mif', 'Local Democracy, Economic Development and ']
      results.last.should ==  ['/home/x/pbc0930106a.mif', 'Construction Bill']
    end
  end
end