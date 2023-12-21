require 'rails_helper'

describe Caffeinate::ScheduleEvaluator do
  before do
    Timecop.freeze
  end

  after do
    Timecop.unfreeze
  end

  context 'on' do
    let(:campaign) do
      campaign = create(:caffeinate_campaign, :with_dripper)
      campaign.to_dripper.drip :welcome, mailer_class: "ArgumentMailier", on: 3.days
      campaign
    end

    let(:sub) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'succeeds' do
      expect(sub.caffeinate_mailings.first.send_at.to_i).to eq 3.days.from_now.to_i
    end
  end

  describe 'periodicals' do
    context 'on and start' do
      let(:campaign) do
        campaign = create(:caffeinate_campaign, :with_dripper)
        campaign.to_dripper.periodical :welcome, mailer_class: "AnyMailer", start: 2.days, every: 24.hours
        campaign
      end

      let(:sub) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

      it 'succeeds' do
        expect(sub.mailings.first.send_at.to_i).to eq 2.days.from_now.to_i
      end

      it 'subsequent mailings use the every key' do
        sub.mailings.first.deliver!

        expect(sub.mailings.last).to_not be(sub.mailings.first)
        expect(sub.mailings.last.send_at).to be_within(10.seconds).of(3.days.from_now)
      end
    end
  end

  context 'at' do
    let(:campaign) do
      campaign = create(:caffeinate_campaign, :with_dripper)
      campaign.to_dripper.drip :welcome, mailer_class: "AnyMailer", on: 3.days, at: :five_pm
      campaign.to_dripper.class_eval do
        def five_pm(evaluator, mailing)
          Time.new(2002, 10, 31, 17, 2, 2)
        end
      end
      campaign
    end

    let(:sub) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'succeeds' do
      expect(sub.mailings.first.send_at.to_i).to eq(3.days.from_now.change(hour: 17, min: 2, sec: 2).to_i)
    end

  end
end
