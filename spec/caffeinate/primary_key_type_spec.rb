# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Primary key type support' do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:user) { create(:user) }

  describe 'Campaign' do
    it 'has the correct id type' do
      expected = ConfigurableSchema.primary_key_type || :integer
      expect(campaign.id).to be_a(expected == :uuid ? String : Integer)
    end
  end

  describe 'CampaignSubscription' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign, subscriber: user) }

    it 'stores subscriber_id with correct type' do
      expect(subscription.subscriber_id).to eq(user.id)
    end

    it 'loads subscriber association correctly' do
      expect(subscription.subscriber).to eq(user)
    end
  end

  describe 'polymorphic association' do
    it 'correctly references subscriber across id types' do
      subscription = campaign.subscribe!(user)
      subscription.reload
      expect(subscription.subscriber).to eq(user)
    end
  end
end
