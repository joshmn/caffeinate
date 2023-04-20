module Caffeinate
  # The RSpec module contains RSpec-specific functionality for Caffeinate.
  module RSpec
    module Matchers
      # Check if the subject subscribes to a given campaign. Only checks for presence.
      #
      # @param expected_campaign [Caffeinate::Campaign] The campaign to be passed as an argument to BeSubscribedTo new.
      # This can be easily accessed via `UserOnboardingDripper.campaign`
      # @return [BeSubscribedTo] A new BeSubscribedTo instance with the expected campaign as its argument.
      def be_subscribed_to_caffeinate_campaign(expected_campaign)
        BeSubscribedToCaffeinateCampaign.new(expected_campaign)
      end

      class BeSubscribedToCaffeinateCampaign
        def initialize(expected_campaign)
          @expected_campaign = expected_campaign
        end

        def description
          "be subscribed to the \"Campaign##{@expected_campaign.slug}\" campaign"
        end

        def failure_message
          "expected #{@hopeful_subscriber.inspect} to be subscribed to the \"Campaign##{@expected_campaign.slug}\" campaign but wasn't"
        end

        def matches?(hopeful_subscriber)
          @hopeful_subscriber = hopeful_subscriber
          @expected_campaign.caffeinate_campaign_subscriptions.exists?(subscriber: hopeful_subscriber)
        end

        def failure_message_when_negated
          "expected #{@hopeful_subscriber.inspect} to not be subscribed to the \"Campaign##{@expected_campaign.slug}\" campaign but was"
        end
      end
    end
  end
end
