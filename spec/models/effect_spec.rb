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
    
    it 'should not continue parsing the file if the headers are not as expected' do
      Bill.should_not_receive(:find_by_name)
      begin
        Effect.load_from_csv_file("./spec/fixtures/DigitalEconomy/effects/effects_with_invalid_headers.csv")
      rescue Exception => e
        e.message.should == "error: unexpected csv header format for effects"
      end
    end
  end
  
end