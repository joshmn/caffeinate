# frozen_string_literal: true

require 'rails_helper'

describe Caffeinate::PeriodicalDrip do
  let!(:campaign) { create(:caffeinate_campaign, :with_dripper) }

  describe 'options' do
    class SomeFakePeriodicalDripper < ::Caffeinate::Dripper::Base
      default mailer_class: "TestMailer"

      periodical :action_name, every: 2.hours
    end

    it 'uses the method' do
      SomeFakePeriodicalDripper.drip_collection.for(:action_name)
      expect(SomeFakePeriodicalDripper.drip_collection.for(:action_name).every).to eq(2.hours)
    end
  end

  context 'perform' do
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    before do
      campaign.to_dripper.class_eval do
        periodical :hello, mailer_class: "ArgumentMailer", every: 1.second, if: :rapture?

        def rapture?(drip, mailing)
          false
        end
      end
    end

    it 'creates another' do
      expect_any_instance_of(campaign.to_dripper).to receive(:rapture?).and_return(true)

      subscription.mailings.last.deliver!
    end
  end

  context 'every' do
    it 'is an error if it is not present' do
      expect { campaign.to_dripper.periodical :hello, mailer_class: "ArgumentMailer" }.to raise_error
    end
  end

end
