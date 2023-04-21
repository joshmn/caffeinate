require 'rails_helper'

require 'caffeinate/rspec'

RSpec.describe Caffeinate::RSpec::Matchers::SubscribeToCaffeinateCampaign do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:company) { create(:company) }
  let(:user) { create(:user) }

  describe 'expected usage' do
    it 'matches' do
      expect { campaign.subscribe(company, user: user) }.to subscribe_to_caffeinate_campaign campaign, company, user: user
    end
  end

  describe '#subscribe_to_caffeinate_campaign' do
    it 'returns instance' do
      expect(subscribe_to_caffeinate_campaign(campaign, company, user: user)).to be_a Caffeinate::RSpec::Matchers::SubscribeToCaffeinateCampaign
    end
  end

  describe '#description' do
    it 'returns description' do
      expect(described_class.new(campaign, company, user: user).description).to eq "subscribe Company##{company.id}/User##{user.id} to the \"Campaign##{campaign.slug}\" campaign"
    end
  end

  describe '#failure_message' do
    it 'returns failure_message' do
      expect(described_class.new(campaign, company, user: user).failure_message).to eq "expected Company##{company.id}/User##{user.id} to subscribe to the \"Campaign##{campaign.slug}\" campaign but didn't"
    end
  end

  describe '#failure_message_when_negated' do
    it 'returns failure_message_when_negated' do
      expect(described_class.new(campaign, company, user: user).failure_message_when_negated).to eq "expected Company##{company.id}/User##{user.id} to not subscribe to the \"Campaign##{campaign.slug}\" campaign but did"
    end
  end

  describe '#matches?' do
    it 'returns true' do
      proc = -> { campaign.subscribe(company, user: user) }

      described_class.new(campaign, company, user: user).matches?(proc)
    end
  end
end
