require 'rails_helper'

require 'caffeinate/rspec'

RSpec.describe Caffeinate::RSpec::Matchers::EndCaffeinateCampaignSubscription do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:company) { create(:company) }
  let(:user) { create(:user) }
  before do
    campaign.subscribe(company, user: user)
  end

  describe 'expected usage' do
    it 'matches' do
      expect { campaign.subscribe(company, user: user).end! }.to end_caffeinate_campaign_subscription campaign, company, user: user
    end
  end

  describe '#end_caffeinate_campaign_subscription' do
    it 'returns instance' do
      expect(end_caffeinate_campaign_subscription(campaign, company, user: user)).to be_a Caffeinate::RSpec::Matchers::EndCaffeinateCampaignSubscription
    end
  end

  describe '#description' do
    it 'returns description' do
      expect(described_class.new(campaign, company, user: user).description).to eq "end the CampaignSubscription of Company##{company.id}/User##{user.id} on the \"Campaign##{campaign.slug}\" campaign"
    end
  end

  describe '#failure_message' do
    it 'returns failure_message' do
      expect(described_class.new(campaign, company, user: user).failure_message).to eq "expected the CampaignSubscription of Company##{company.id}/User##{user.id} on the \"Campaign##{campaign.slug}\" campaign to end but didn't"
    end
  end

  describe '#failure_message_when_negated' do
    it 'returns failure_message_when_negated' do
      expect(described_class.new(campaign, company, user: user).failure_message_when_negated).to eq "expected the CampaignSubscription of Company##{company.id}/User##{user.id} on the \"Campaign##{campaign.slug}\" campaign to not end but did"
    end
  end

  describe '#matches?' do
    it 'returns true' do
      proc = -> { campaign.subscribe(company, user: user) }

      described_class.new(campaign, company, user: user).matches?(proc)
    end
  end
end
