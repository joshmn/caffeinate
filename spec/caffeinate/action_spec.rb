require 'rails_helper'

describe Caffeinate::Action do
  class CoolOneOffAction < Caffeinate::Action
    def return_nil(mailing)

    end

    def return_mailing(mailing)
      mailing
    end

    class Envelope
      def initialize(user)
        @user = user
      end

      def deliver!(action_object)
        # ERB.new(File.read(Rails.root + "app/views/cool_one_off_action/#{action_object.action_name}.html.erb"))
        #
      end
    end

    def return_custom_thing(mailing)
      Envelope.new(mailing.subscriber)
    end
  end

  let!(:campaign) { create(:caffeinate_campaign, :with_dripper) }

  before do
    # name doesn't matter here since we're invoking things directly
    # we just want the mailing to exist
    campaign.to_dripper.drip :hello, action_class: 'CoolOneOffAction', delay: 0.hours
  end

  let(:subscription) { create(:caffeinate_campaign_subscription, caffeinate_campaign: campaign) }
  let(:mailing) { subscription.caffeinate_mailings.first }

  context '#process' do
    subject do
      instance = described_class.new
      instance.process(:welcome, mailing)
      instance
    end

    it 'sets the @action_name' do
      expect(subject.action_name).to eq(:welcome)
    end

    it 'sets the #caffeinate_mailing' do
      expect(subject.caffeinate_mailing).to eq(mailing)
    end

    it 'sets has a Caffeinate::Mailing' do
      expect(subject.caffeinate_mailing).to be_a(Caffeinate::Mailing)
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

    it 'marks the mailing as sent' do
      expect { subject }.to change(mailing, :sent_at)
    end
  end

  context 'when an action returns an object that responds to #deliver!' do
    it 'calls it' do
      expect_any_instance_of(CoolOneOffAction::Envelope).to receive(:deliver!).with(an_instance_of(CoolOneOffAction)).and_call_original
      CoolOneOffAction.return_custom_thing(mailing).deliver
    end

    it 'marks mailing as sent' do
      expect { CoolOneOffAction.return_custom_thing(mailing).deliver }.to change(mailing, :sent_at)
    end
  end

  context 'when an action returns a mailing' do
    it 'does not hit its deliver!' do
      expect(mailing).to_not receive(:deliver!)
      CoolOneOffAction.return_mailing(mailing).deliver
    end

    it 'marks mailing as sent' do
      expect { CoolOneOffAction.return_mailing(mailing).deliver }.to change(mailing, :sent_at)
    end
  end

  context 'when an action returns an envelope that raises an error' do
    subject do
      allow_any_instance_of(CoolOneOffAction::Envelope).to receive(:deliver!).and_raise(StandardError)
      CoolOneOffAction.return_custom_thing(mailing).deliver
    end

    it 'raises the error' do
      expect { subject }.to raise_error(StandardError)
    end

    it 'does not change the mail' do


      expect { subject rescue StandardError }.to_not change(mailing, :sent_at)
    end
  end
end
