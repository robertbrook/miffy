require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Act do

  describe 'when created from name' do
    it 'should remove duplicate spaces from name' do
      name = 'Income Tax (Trading and Other Income) Act  (c. 5)'
      squeezed = 'Income Tax (Trading and Other Income) Act (c. 5)'
      Act.should_receive(:find_by_name).with(squeezed).and_return nil
      Act.should_receive(:find_by_title).with(squeezed).and_return nil
      Act.should_receive(:create!).with(:name => squeezed)
      Act.from_name name
    end

    it 'should put space between (c. and digit) when reading a Chapter reference' do
      name = 'Income Tax (Trading and Other Income) Act  (c.5)'
      normalized = 'Income Tax (Trading and Other Income) Act (c. 5)'
      Act.should_receive(:find_by_name).with(normalized).and_return nil
      Act.should_receive(:find_by_title).with(normalized).and_return nil
      Act.should_receive(:create!).with(:name => normalized)
      Act.from_name name
    end
  end
end