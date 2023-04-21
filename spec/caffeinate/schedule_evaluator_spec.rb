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

    let(:sub) { create(:caffeinate_campaign_subscription, campaign: campaign) }

    it 'succeeds' do
      assert sub.caffeinate_mailings.first.send_at == 3.days.from_now
    end
  end

  describe 'periodicals' do
    context 'on and start' do
      let(:campaign) do
        campaign = create(:caffeinate_campaign, :with_dripper)
        campaign.to_dripper.periodical :welcome, mailer_class: "AnyMailer", start: 2.days, every: 24.hours
        campaign
      end

      let(:sub) { create(:caffeinate_campaign_subscription, campaign: campaign) }

      it 'succeeds' do
        assert sub.mailings.first.send_at == 2.days.from_now
      end

      it 'subsequent mailings use the every key' do
        sub.mailings.first.deliver!

        assert sub.mailings.last != sub.mailings.first
        assert sub.mailings.last.send_at == 3.days.from_now
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

    let(:sub) { create(:caffeinate_campaign_subscription, campaign: campaign) }

    it 'succeeds' do
      assert sub.mailings.first.send_at == 3.days.from_now.change(hour: 17, min: 2, sec: 2)
    end

  end
end
