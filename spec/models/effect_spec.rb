require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Effect do
  
  describe 'when reading the table of effects file' do
    it 'should create new Effects records when a matching Bill is found' do
      Effect.should_receive(:create).exactly(4).times
      Bill.should_receive(:find_by_name).exactly(4).times.and_return mock_model(Bill, :id => 1)
      Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/effects_with_4_records.csv")
    end
    
    it 'should not create new Effects records when a matching Bill is not found' do
      Effect.should_not_receive(:create)
      Bill.should_receive(:find_by_name).exactly(4).times.and_return nil
      Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/effects_with_4_records.csv")
    end
    
    it 'should create 2 records where 2 references are given in the Affecting Provision column' do
      Effect.should_receive(:create).exactly(2).times
      Bill.should_receive(:find_by_name).and_return mock_model(Bill, :id => 1)
      Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/single_effect_with_2_refs.csv")
    end
    
    it 'should not create a record given an invalid reference' do
      Effect.should_not_receive(:create)
      Bill.should_receive(:find_by_name).and_return mock_model(Bill, :id => 1)
      Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/single_effect_with_invalid_ref.csv")
    end
    
    it 'should not continue parsing the file if the headers are not as expected' do
      Bill.should_not_receive(:find_by_name)
      begin
        Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/effects_with_invalid_headers.csv")
      rescue Exception => e
        e.message.should == "error: unexpected csv header format for effects"
      end
    end
  end
  
  describe 'when parsing a reference to the Bill' do
    it 'should return an array containing the clause reference and the parsed string when passed an effects clause reference' do
      Effect.parse_bill_provision_reference("s. 001").should == ["clause1", "s. 001"]
      Effect.parse_bill_provision_reference("s. 001(06)").should == ["clause1-6", "s. 001(06)"]
      Effect.parse_bill_provision_reference("s. 001(06)(b)").should == ["clause1-6-b", "s. 001(06)(b)"]
    end
    
    it 'should return an array containing the schedule reference and the parsed string when passed an effects schedule reference' do
      Effect.parse_bill_provision_reference("Sch. 01").should == ["schedule1", "Sch. 01"]
      Effect.parse_bill_provision_reference("Sch. 01 para. 006").should == ["schedule1-6", "Sch. 01 para. 006"]
      Effect.parse_bill_provision_reference("Sch. 01 para. 006(04)").should == ["schedule1-6-4", "Sch. 01 para. 006(04)"]
      Effect.parse_bill_provision_reference("Sch. 01 para. 006(04)(c)").should == ["schedule1-6-4-c", "Sch. 01 para. 006(04)(c)"]
    end
    
    it 'should return and array of [nil, ''] if passed an invalid reference string' do
      Effect.parse_bill_provision_reference("invalid string").should == [nil, ""]
    end
    
    it 'should return results for the first match if passed a string containing more than one reference' do
      Effect.parse_bill_provision_reference("s. 001 s.002(08)").should == ["clause1", "s. 001"]
      Effect.parse_bill_provision_reference("Sch. 01 para. 006 s.002(08)").should == ["schedule1-6", "Sch. 01 para. 006"]
    end
  end
  
end