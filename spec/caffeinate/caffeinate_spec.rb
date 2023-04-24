require 'rails_helper'

describe Caffeinate do
  describe '.dripper_collection' do
    it 'returns the DripperCollection instance' do
      expect(described_class.dripper_collection).to be_an_instance_of(Caffeinate::DripperCollection)
    end

    it 'memoizes the DripperCollection instance' do
      expect(described_class.dripper_collection).to eq(described_class.dripper_collection)
    end
  end

  describe '.config' do
    it 'returns the Configuration instance' do
      expect(described_class.config).to be_an_instance_of(Caffeinate::Configuration)
    end

    it 'memoizes the Configuration instance' do
      expect(described_class.config).to eq(described_class.config)
    end
  end

  describe '.setup' do
    it 'yields the configuration object' do
      described_class.setup do |config|
        expect(config).to eq(described_class.config)
      end
    end
  end
end
