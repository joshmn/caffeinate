require 'rails_helper'

describe CampaignSubscriptions::RefuelService do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

  before do
    campaign.to_dripper.drip :one, mailer_class: 'ArgumentMailer', delay: 1.minutes
    campaign.to_dripper.drip :two, mailer_class: 'ArgumentMailer', delay: 2.minutes
    campaign.to_dripper.drip :three, mailer_class: 'ArgumentMailer', delay: 3.minutes
  end

  context 'invalid args' do
    it 'yells' do
      expect { subject.new(subscription, offset: :donkey) }.to raise_error(ArgumentError)
    end
  end

  describe 'offset' do
    context 'created_at' do
      it 'uses the subscription created_at time for the send_at' do
        Timecop.freeze do
          mailing = subscription.mailings.last.destroy
          expected_time = mailing.send_at

          described_class.new(subscription, offset: :created_at).call
          expect(subscription.mailings.last.send_at).to eq(expected_time)
        end
      end
    end

    context 'current' do
      it 'uses the current time for the send_at offset' do
        Timecop.travel(3.hours.ago) do
          subscription.mailings.last.destroy
        end

        Timecop.travel(5.hours.from_now) do
          described_class.new(subscription, offset: :current).call
          expect(subscription.mailings.last.send_at.to_i).to eq((Caffeinate.config.now.call + 3.minutes).to_i)
        end
      end
    end
  end

end
