# frozen_string_literal: true

require 'rails_helper'

describe ::Caffeinate::Dripper::Perform do
  let!(:campaign) { create(:caffeinate_campaign, slug: 'perform_dripper') }

  class PerformMailer < ApplicationMailer
    def welcome(_)
      mail(to: 'test@example.com', from: 'test@example.com', subject: 'hello') do |format|
        format.text { render plain: 'hello' }
      end
    end
  end

  class PerformDripper < ::Caffeinate::Dripper::Base
    self.campaign = :perform_dripper
    default mailer_class: 'PerformMailer'

    drip :welcome, delay: 1.hour
  end

  describe '#perform' do
    context 'with a future mail' do
      let!(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

      it 'does not send mail' do
        expect do
          PerformDripper.perform!
        end.not_to change(ActionMailer::Base.deliveries, :size)
      end
    end

    context 'with a past mail' do
      let!(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

      it 'sends mail' do
        Timecop.travel(2.hours.from_now) do
          expect do
            PerformDripper.perform!
          end.to change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end
  end

  describe '#upcoming_mailings' do
    it 'is a relation of Caffeinate::Mailing' do
      expect(PerformDripper.upcoming_mailings.to_sql).to include(::Caffeinate::Mailing.table_name)
    end
  end

  describe 'action classes' do
    class TestActionClass < Caffeinate::ActionProxy
      class FakeDelivery
        def initialize

        end

        def deliver!(thing)

        end
      end

      def welcome(mailing)
        FakeDelivery.new
      end
    end

    class PerformActionDripper < Caffeinate::Dripper::Base
      self.campaign = :perform_action_dripper

      drip :welcome, delay: -1.hour, action_class: "TestActionClass"
    end

    let!(:campaign) { create(:caffeinate_campaign, slug: 'perform_action_dripper') }
    let(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'invokes the action' do
      expect_any_instance_of(TestActionClass).to receive(:welcome).with(campaign_subscription.mailings.first).and_call_original
      PerformActionDripper.perform!
    end

    it 'marks the mailing as sent' do
      mailing = campaign_subscription.mailings.first
      expect(mailing.sent_at).to be_nil
      PerformActionDripper.perform!
      expect(mailing.reload.sent_at).to be_present
    end
  end
end
