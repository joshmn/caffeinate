require 'rails_helper'

require 'caffeinate/rspec'

RSpec.describe Caffeinate::RSpec::Matchers::BeSubscribedToCaffeinateCampaign do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:user) { create(:user) }

  describe 'expected usage' do
    subject { campaign.subscribe(user) }

    it 'matches' do
      expect(subject.subscriber).to be_subscribed_to_caffeinate_campaign campaign
    end

    context 'with' do
      let(:company) { create(:company) }

      subject { campaign.subscribe(company, user: user) }

      it 'matches' do
        expect(subject.subscriber).to be_subscribed_to_caffeinate_campaign(campaign).with(user: user)
      end
    end
  end

  describe '#be_subscribed_to' do
    it 'returns instance' do
      expect(be_subscribed_to_caffeinate_campaign(campaign)).to be_a Caffeinate::RSpec::Matchers::BeSubscribedToCaffeinateCampaign
    end
  end

  describe '#description' do
    it 'returns description' do
      expect(described_class.new(campaign).description).to eq "be subscribed to the \"Campaign##{campaign.slug}\" campaign"
    end
  end

  describe '#failure_message' do
    it 'returns failure_message' do
      expect(described_class.new(campaign).failure_message).to eq "expected nil to be subscribed to the \"Campaign##{campaign.slug}\" campaign but wasn't"
    end
  end

  describe '#failure_message_when_negated' do
    it 'returns failure_message_when_negated' do
      expect(described_class.new(campaign).failure_message_when_negated).to eq "expected nil to not be subscribed to the \"Campaign##{campaign.slug}\" campaign but was"
    end
  end

  describe '#matches?' do
    before do
      campaign.subscribe(user)
    end

    it 'returns true' do
      described_class.new(campaign).matches?(user)
    end
  end
end
