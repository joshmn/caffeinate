# frozen_string_literal: true

require 'rails_helper'

describe Caffeinate::CampaignSubscription do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

  describe '#next_mailing' do
    it 'has a mailing if the campaign is active' do
      mailing = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.ago)
      mailing_2 = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.from_now)
      expect(subscription.next_mailing).to eq(mailing)
    end
    it 'does not have a next_mailing if the campaign is ended' do
      mailing = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.ago)
      mailing_2 = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.from_now)
      subscription.end!
      expect(subscription.next_mailing).to be_nil
    end
    it 'does not have a next_mailing if the campaign is unsubscribed' do
      mailing = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.ago)
      mailing_2 = subscription.mailings.create!(mailer_class: "Test", mailer_action: "test", send_at: 1.hour.from_now)
      subscription.unsubscribe!
      expect(subscription.next_mailing).to be_nil
    end
  end

  describe '#refuel!' do
    it 'invokes the RefuelService' do
      expect_any_instance_of(::CampaignSubscriptions::RefuelService).to receive(:call)
      subscription.refuel!
    end
  end

  describe '#end!' do
    context 'without argument' do
      it 'is not ended' do
        expect(subscription).not_to be_ended
      end

      context 'after #end!' do
        before do
          subscription.end!
        end

        it 'is #ended?' do
          expect(subscription).to be_ended
        end

        it 'has #ended_at' do
          expect(subscription.ended_at).to be_between(1.second.ago, Time.current)
        end

        it 'does not update #ended_reason' do
          expect(subscription.ended_reason).to be_blank
        end
      end
    end

    context 'with argument' do
      before do
        subscription.end!("no more pasta")
      end

      it 'is #ended?' do
        expect(subscription).to be_ended
      end

      it 'has #ended_at' do
        expect(subscription.ended_at).to be_between(1.second.ago, Time.current)
      end

      it 'does not update #ended_reason' do
        expect(subscription.ended_reason).to eq("no more pasta")
      end
    end
  end

  describe '#unsubscribe!' do
    context 'without argument' do
      it 'is not unsubscribed' do
        expect(subscription).not_to be_unsubscribed
      end

      context 'after #unsubscribe!' do
        before do
          subscription.unsubscribe!
        end

        it 'is #ended?' do
          expect(subscription).to be_unsubscribed
        end

        it 'has #ended_at' do
          expect(subscription.unsubscribed_at).to be_between(1.second.ago, Time.current)
        end

        it 'does not update #unsubscribe_reason' do
          expect(subscription.unsubscribe_reason).to be_blank
        end
      end
    end

    context 'with argument' do
      before do
        subscription.unsubscribe!("no more pasta")
      end

      it 'is #unsubscribed?' do
        expect(subscription).to be_unsubscribed
      end

      it 'has #unsubscribed_at' do
        expect(subscription.unsubscribed_at).to be_between(1.second.ago, Time.current)
      end

      it 'does not update #unsubscribe_reason' do
        expect(subscription.unsubscribe_reason).to eq("no more pasta")
      end
    end
  end

  describe '#subscribed?' do
    it 'is true if ended_at is nil' do
      subscription.ended_at = nil
      expect(subscription).to be_subscribed
    end

    it 'false if ended_at is present' do
      subscription.ended_at = Time.current
      expect(subscription).not_to be_subscribed
    end

    it 'is false if unsubscribed_at is present' do
      subscription.unsubscribed_at = Time.current
      expect(subscription).not_to be_subscribed
    end

    it 'is false if ended_at and unsubscribed at are both somehow present' do
      subscription.ended_at = Time.current
      subscription.unsubscribed_at = Time.current
      expect(subscription).not_to be_subscribed
    end

    it 'is false if ended_at and unsubscribed at are both somehow present and resubscribed_at is present' do
      subscription.ended_at = Time.current
      subscription.unsubscribed_at = Time.current
      subscription.resubscribed_at = Time.current
      expect(subscription).not_to be_subscribed
    end
  end

  describe '#validations' do
    before do
      campaign.to_dripper.before_subscribe do |campaign_subscription|
        campaign_subscription.errors.add(:base, "is invalid")
        throw(:abort)
      end
    end

    after do
      campaign.to_dripper.instance_variable_set(:@before_subscribe_blocks, [])
    end

    it 'calls before_subscribe blocks and invalidates accordingly' do
      user = create(:user)
      expect {
        subscription = campaign.to_dripper.subscribe(user)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'multiple subscriptions' do
    it 'creates a new active subscription' do
      user = create(:user)
      sub = campaign.subscribe!(user)
      sub.end!
      sub2 = campaign.subscribe!(user)
      expect(sub2).to_not eq(sub)
    end

    it 'returns an existing subscription if it is only unsubscribed' do
      user = create(:user)
      sub = campaign.subscribe!(user)
      sub.unsubscribe!
      sub2 = campaign.subscribe!(user)
      expect(sub2).to eq(sub)
    end

    it 'returns the existing if there is an active sub' do
      user = create(:user)
      sub = campaign.subscribe!(user)
      sub2 = campaign.subscribe!(user)
      expect(sub2).to eq(sub)
    end
  end

  describe 'on destroy' do
    it 'does not run on_complete' do
      allow(subscription).to receive(:completed?).and_return(true)
      expect(subscription).to_not receive(:on_complete)
      subscription.destroy!
    end
  end

end
