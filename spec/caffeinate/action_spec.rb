require 'rails_helper'

describe Caffeinate::Action do
  class CoolOneOffAction < Caffeinate::Action
    def return_nil(mailing)

    end

    def return_mailing(mailing)
      mailing
    end

    class ImplementsDelivery
      def initialize

      end

      def deliver!(mailing)
      end
    end

    def return_custom_thing(mailing)
      ImplementsDelivery.new
    end
  end

  let!(:campaign) { create(:caffeinate_campaign, :with_dripper) }
  let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }
  let(:mailing) { subscription.mailings.first }

  context '#process' do
    subject do
      instance = described_class.new
      instance.process(:welcome, mailing)
      instance
    end

    it 'sets the @action_name' do
      expect(subject.instance_variable_get(:@action_name)).to eq(:welcome)
    end

    it 'sets the #caffeinate_mailing' do
      expect(subject.caffeinate_mailing).to eq(mailing)
    end
  end

  context '#deliver' do
    subject do
      CoolOneOffAction.return_nil(mailing).deliver
    end

    it 'informs interceptors' do
      expect_any_instance_of(described_class).to receive(:inform_interceptors)
      subject
    end

    it 'informs observers' do
      expect_any_instance_of(described_class).to receive(:inform_observers)
      subject
    end

    it 'calls do_delivery' do
      expect_any_instance_of(described_class).to receive(:do_delivery)
      subject
    end
  end

  context 'when an action returns an object that responds to #deliver!' do

    before do
      campaign.to_dripper.drip :hello, mailer_class: 'ArgumentMailer', delay: 0.hours
    end

    let(:mailing) { subscription.caffeinate_mailings.first }
    let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }

    it 'calls it' do
      expect_any_instance_of(CoolOneOffAction::ImplementsDelivery).to receive(:deliver!)
      CoolOneOffAction.return_custom_thing(mailing).deliver
    end
  end

end
