# frozen_string_literal: true

require 'rails_helper'

describe ::Caffeinate::Dripper::Periodical do
  class PeriodicalMailer < ApplicationMailer
    def welcome(_)
      mail(to: 'test@example.com', from: 'test@example.com', subject: 'hello') do |format|
        format.text { render plain: 'hello' }
      end
    end
  end

  class PeriodicalDripper < ::Caffeinate::Dripper::Base
    self.campaign = :periodical_dripper
    default mailer_class: 'PeriodicalMailer'

    periodical :welcome, every: 1.hour, start: -> { 30.minutes }
  end

  describe '.periodical_static' do
    let!(:campaign) { create(:caffeinate_campaign, slug: 'periodical_dripper') }
    let!(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'has a single mailing' do
      expect(campaign_subscription.caffeinate_mailings.count).to eq(1)
    end

    it "correctly sets the first mailing to the `start` offset" do
      expect(campaign_subscription.caffeinate_mailings.first.send_at).to be_within(1.second).of(Time.current + 30.minutes)
    end

    context 'with performed dripper' do
      let(:perform) { Timecop.travel(1.hour.from_now); PeriodicalDripper.perform! }

      it 'changes deliveries count' do
        expect do
          perform
        end.to change(ActionMailer::Base.deliveries, :size).by(1)
      end

      it "creates another mailing and sets the send_at to exactly the interval (`start` no longer matters)" do
        perform

        expect(campaign_subscription.caffeinate_mailings.count).to eq 2
        expect(campaign_subscription.caffeinate_mailings.last.send_at).to be_within(1.second).of(1.hour.from_now)
      end

      it 'creates an unsent mailing' do
        perform
        expect(campaign_subscription.caffeinate_mailings.unsent.count).to eq(1)
      end

      it 'sends a mail' do
        perform
        expect(campaign_subscription.caffeinate_mailings.unsent.first.send_at).to be_within(1.seconds).of(1.hour.from_now)
      end
    end
  end

  class DynamicPeriodicalDripper < ::Caffeinate::Dripper::Base
    self.campaign = :dynamic_periodical_dripper
    default mailer_class: 'PeriodicalMailer'

    periodical :welcome, every: -> { 2.weeks + rand(0..60).minutes }, start: -> { 0.hours }, until: Time.parse("01/01/2020") + 3.weeks
  end

  describe '.periodical_dynamic' do
    let!(:campaign) { create(:caffeinate_campaign, slug: 'dynamic_periodical_dripper') }
    let!(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'has a single mailing' do
      expect(campaign_subscription.caffeinate_mailings.count).to eq(1)
    end

    it "correctly sets the first mailing to the `start` offset" do
      expect(campaign_subscription.caffeinate_mailings.first.send_at).to be_within(1.second).of(Time.current)
    end

    context 'with performed dripper' do
      let(:perform) { Timecop.travel(1.second.from_now); DynamicPeriodicalDripper.perform! }

      it 'changes deliveries count' do
        expect do
          perform
        end.to change(ActionMailer::Base.deliveries, :size).by(1)
      end

      it "creates another mailing and sets the send_at to exactly the interval (`start` no longer matters)" do
        perform

        expect(campaign_subscription.caffeinate_mailings.count).to eq 2
        expect(campaign_subscription.caffeinate_mailings.last.send_at).to be_within(60.minutes).of(2.weeks.from_now)
      end

      it 'creates an unsent mailing' do
        perform
        expect(campaign_subscription.caffeinate_mailings.unsent.count).to eq(1)
      end

      it 'sends a mail' do
        perform
        expect(campaign_subscription.caffeinate_mailings.unsent.first.send_at).to be_within(60.minutes).of(2.weeks.from_now)
      end

      it "stops after the first mailing because the until: is short" do

        perform # first run

        m = campaign_subscription.caffeinate_mailings.unsent.last

        Timecop.travel(3.weeks.from_now)
        DynamicPeriodicalDripper.perform! # second run

        expect(m.reload.sent_at).to_not be_nil
        expect(campaign_subscription.caffeinate_mailings.count).to eq 2 # no third
      end
    end
  end

  class ProcUntilDripper < ::Caffeinate::Dripper::Base
    self.campaign = :proc_until
    default mailer_class: 'PeriodicalMailer'

    periodical :welcome, every: -> { 2.weeks + rand(0..60).minutes }, start: -> { 0.hours }, until: -> { send_at.month >= 2 }
  end

  describe '.periodical_dynamic' do
    let!(:campaign) { create(:caffeinate_campaign, slug: 'proc_until') }
    let!(:campaign_subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    context 'with performed dripper' do
      it "stops after the first mailing because the until: is short" do
        expect(campaign_subscription.caffeinate_mailings.count).to eq 1
        m = campaign_subscription.caffeinate_mailings.unsent.last

        Timecop.travel(1.second.from_now)
        ProcUntilDripper.perform! # first run

        expect(m.reload.sent_at).to_not be_nil # first message was sent
        expect(campaign_subscription.caffeinate_mailings.count).to eq 2 # second created
        m = campaign_subscription.caffeinate_mailings.unsent.last

        Timecop.travel(m.send_at + 1.second)
        ProcUntilDripper.perform! # second run

        expect(m.reload.sent_at).to_not be_nil # second message was sent
        expect(campaign_subscription.caffeinate_mailings.count).to eq 3 # third created
        m = campaign_subscription.caffeinate_mailings.unsent.last

        Timecop.travel(m.send_at + 1.second)
        ProcUntilDripper.perform! # third run — now would be into February

        expect(m.reload.sent_at).to_not be_nil # third message was sent
        expect(campaign_subscription.caffeinate_mailings.count).to eq 3 # no fourth message created
      end
    end
  end
end
