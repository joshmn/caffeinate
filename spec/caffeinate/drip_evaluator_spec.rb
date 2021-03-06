# frozen_string_literal: true

require 'rails_helper'

describe ::Caffeinate::DripEvaluator do
  class DripEvaluatorMailer < ActionMailer::Base
    def hello_end; end

    def hello_skip; end

    def hello_unsubscribe; end
  end

  class DripEvaluatorDripper < ::Caffeinate::Dripper::Base
    self.campaign = :drip_evaluator
    default mailer_class: 'DripEvaluatorMailer', using: :parameterized
    drip :hello_end, delay: 0.hours do
      end!
    end
    drip :hello_skip, delay: 0.hours do
      skip!
    end
    drip :hello_unsubscribe, delay: 0.hours do
      unsubscribe!
    end
  end

  class DripEvaluatorReasonDripper < ::Caffeinate::Dripper::Base
    self.campaign = :drip_reason_evaluator
    default mailer_class: 'DripEvaluatorMailer', using: :parameterized
    drip :hello_end, delay: 0.hours do
      end!("I ended")
    end
    drip :hello_unsubscribe, delay: 0.hours do
      unsubscribe!("I unsubscribed")
    end
  end

  let!(:campaign) { create(:caffeinate_campaign, slug: 'drip_evaluator') }
  let!(:campaign_reason) { create(:caffeinate_campaign, slug: 'drip_reason_evaluator') }

  describe '#end!' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }
    let(:mailing) { subscription.caffeinate_mailings.find_by(mailer_action: 'hello_end') }

    before do
      described_class.new(mailing).call(&mailing.drip.block)
    end

    it 'calls #end! on the campaign_subscription' do
      mailing.reload
      expect(mailing.caffeinate_campaign_subscription).to be_ended
    end

    it 'call returns false' do
      result = described_class.new(mailing).call(&mailing.drip.block)
      expect(result).to be_falsey
    end
  end

  describe '#end! with reason' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign_reason) }
    let(:mailing) { subscription.caffeinate_mailings.find_by(mailer_action: 'hello_end') }
    before do
      described_class.new(mailing).call(&mailing.drip.block)
    end

    it 'is ended' do
      expect(mailing.caffeinate_campaign_subscription).to be_ended
    end

    it 'has an ended_reason' do
      expect(mailing.caffeinate_campaign_subscription.ended_reason).to be_present
    end

    it 'block returns false' do
      result = described_class.new(mailing).call(&mailing.drip.block)
      expect(result).to be_falsey
    end
  end

  describe '#unsubscribe!' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }
    let(:mailing) { subscription.caffeinate_mailings.find_by(mailer_action: 'hello_unsubscribe') }

    it 'calls #unsubscribe! on the campaign_subscription' do
      described_class.new(mailing).call(&mailing.drip.block)
      mailing.reload
      expect(mailing.caffeinate_campaign_subscription).to be_unsubscribed
    end

    it 'returns false' do
      result = described_class.new(mailing).call(&mailing.drip.block)
      expect(result).to be_falsey
    end
  end

  describe '#unsubscribe! with reason' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign_reason) }
    let(:mailing) { subscription.caffeinate_mailings.find_by(mailer_action: 'hello_unsubscribe') }

    before do
      described_class.new(mailing).call(&mailing.drip.block)
    end

    it 'calls #unsubscribe! on the campaign_subscription' do
      mailing.reload
      expect(mailing.caffeinate_campaign_subscription).to be_unsubscribed
    end

    it 'has a reason' do
      expect(mailing.caffeinate_campaign_subscription.unsubscribe_reason).to be_present
    end

    it 'returns false' do
      result = described_class.new(mailing).call(&mailing.drip.block)
      expect(result).to be_falsey
    end
  end

  describe '#skip!' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }
    let(:mailing) { subscription.caffeinate_mailings.find_by(mailer_action: 'hello_skip') }

    it 'calls #skip! on the mailing' do
      described_class.new(mailing).call(&mailing.drip.block)
      mailing.reload
      expect(mailing).to be_skipped
    end

    it 'returns false' do
      result = described_class.new(mailing).call(&mailing.drip.block)
      expect(result).to be_falsey
    end
  end
end
