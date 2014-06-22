require 'spec_helper'

describe Gird::PhraseBank do
  describe '#add' do
    it 'should add a phrase' do
      subject.add 'something', 'Something'
      subject.to_json.should == {
        'something' => 'Something'
      }.to_json
    end

    it 'should accept an empty phrase override' do
      subject.add 'something', nil
      subject.to_hash.should == { "something" => "" }
      subject.add 'something', 'Something'
      subject.to_hash.should == { "something" => "Something" }
    end

    it 'should reject duplicates' do
      subject.add 'something', 'Something'
      expect {
        subject.add 'something', 'Else'
      }.to raise_error(Gird::PhraseError)
    end
  end

  describe '#merge' do
    it 'should merge phrases with those from another bank' do
      other_bank = self.described_class.new
      other_bank.add 'something', 'Something'
      subject.merge(other_bank)
      subject.to_hash.should == { "something" => "Something" }
    end
  end
end