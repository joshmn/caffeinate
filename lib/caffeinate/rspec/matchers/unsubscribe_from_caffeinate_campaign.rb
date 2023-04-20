module Caffeinate
  # The RSpec module contains RSpec-specific functionality for Caffeinate.
  module RSpec
    module Matchers
      # Creates an RSpec matcher for testing whether an action results in an unsubscribe from a specified campaign.
      #
      # @param expected_campaign [Caffeinate::Campaign] The expected campaign.
      # @param subscriber [Object] The subscriber being tested.
      # @param args [Hash] Additional arguments passed to the Caffeinate::CampaignSubscriber.
      # @option args [Object] :user The user associated with the subscriber.
      # @return [UnsubscribeFromCaffeinateCampaign] The created matcher object.
      def unsubscribe_from_caffeinate_campaign(expected_campaign, subscriber, **args)
        UnsubscribeFromCaffeinateCampaign.new(expected_campaign, subscriber, **args)
      end

      class UnsubscribeFromCaffeinateCampaign
        def initialize(expected_campaign, subscriber, **args)
          @expected_campaign = expected_campaign
          @subscriber = subscriber
          @args = args
        end

        def description
          "unsubscribe #{who} from the \"Campaign##{@expected_campaign.slug}\" campaign"
        end

        def failure_message
          "expected #{who} to unsubscribe from the \"Campaign##{@expected_campaign.slug}\" campaign but didn't"
        end

        # Checks whether the block results in an unsubscribe from the expected campaign.
        #
        # @param block [Block] The block of code to execute.
        def matches?(block)
          sub = @expected_campaign.caffeinate_campaign_subscriptions.active.find_by(subscriber: @subscriber, **@args)
          return false unless sub && sub.subscribed?

          block.call
          sub.reload.unsubscribed?
        end

        def failure_message_when_negated
          "expected #{who} to not unsubscribe from the \"Campaign##{@expected_campaign.slug}\" campaign but did"
        end

        def supports_block_expectations?
          true
        end

        private

        def who
          str = "#{@subscriber.class.name}##{@subscriber.to_param}"
          user = @args[:user]
          if user
            str << "/#{user.class.name}##{user.to_param}"
          end
          if @args.except(:user).any?
            str << "/#{@args.except(:user).inspect}"
          end
          str
        end
      end
    end
  end
end
