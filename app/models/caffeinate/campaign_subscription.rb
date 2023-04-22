# frozen_string_literal: true

# == Schema Information
#
# Table name: caffeinate_campaign_subscriptions
#
#  id                     :integer          not null, primary key
#  caffeinate_campaign_id :integer          not null
#  subscriber_type        :string           not null
#  subscriber_id          :string           not null
#  user_type              :string
#  user_id                :string
#  token                  :string           not null
#  ended_at               :datetime
#  unsubscribed_at        :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

module Caffeinate
  # If a record tries to be `unsubscribed!` or `ended!` or `resubscribe!` and it's in a state that is not
  # correct, raise this
  class InvalidState < ::ActiveRecord::RecordInvalid; end

  # CampaignSubscription associates an object and its optional user to a Campaign
  # and its relevant Mailings.
  class CampaignSubscription < ApplicationRecord
    self.table_name = 'caffeinate_campaign_subscriptions'

    has_many :caffeinate_mailings, class_name: 'Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id, dependent: :destroy
    has_many :mailings, class_name: 'Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id, dependent: :destroy
    has_many :future_mailings, -> { upcoming.unsent }, class_name: '::Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id

    has_one :next_caffeinate_mailing, -> { joins(:caffeinate_campaign_subscription).where(caffeinate_campaign_subscriptions: { ended_at: nil, unsubscribed_at: nil }).upcoming.unsent.order(send_at: :asc) }, class_name: '::Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id
    has_one :next_mailing, -> { joins(:caffeinate_campaign_subscription).where(caffeinate_campaign_subscriptions: { ended_at: nil, unsubscribed_at: nil }).upcoming.unsent.order(send_at: :asc) }, class_name: '::Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id

    has_one :previous_caffeinate_mailing, -> { sent.order(sent_at: :desc) }, class_name: '::Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id
    has_one :previous_mailing, -> { sent.order(sent_at: :desc) }, class_name: '::Caffeinate::Mailing', foreign_key: :caffeinate_campaign_subscription_id

    belongs_to :caffeinate_campaign, class_name: 'Caffeinate::Campaign', foreign_key: :caffeinate_campaign_id
    alias_attribute :campaign, :caffeinate_campaign

    belongs_to :subscriber, polymorphic: true
    belongs_to :user, polymorphic: true, optional: true

    # All CampaignSubscriptions that where `unsubscribed_at` is nil and `ended_at` is nil
    scope :active, -> { where(unsubscribed_at: nil, ended_at: nil) }
    scope :subscribed, -> { active }
    scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

    # All CampaignSubscriptions that where `ended_at` is not nil
    scope :ended, -> { where.not(ended_at: nil) }

    before_validation :set_token!, on: [:create]
    validates :token, uniqueness: true, on: [:create]

    before_validation :call_dripper_before_subscribe_blocks!, on: :create

    after_create :create_mailings!

    after_commit :on_complete, if: :completed?, unless: :destroyed?

    # Add (new) drips to a `CampaignSubscriber`.
    #
    # Useful if you added new drips to a `Campaign` and have existing `CampaignSubscription`
    # which you want to add them to.
    #
    # Pass `:created_at` if you want to offset `Mailing#send_at` time from the time the `CampaignSubscription`
    # was originally created. That is to say that if you add a new drip for 5 days from now, the mailing will be sent
    # 5 days from when the `CampaignSubscription` was created.
    #
    # Pass `:current` to offset from the current time (doesn't offset anything, actually)
    def refuel!(offset: :created_at)
      ::CampaignSubscriptions::RefuelService.new(self, offset: offset).call

      true
    end

    # Actually deliver and process the mail
    def deliver!(mailing)
      caffeinate_campaign.to_dripper.deliver!(mailing)
    end

    # Checks if the `CampaignSubscription` is not ended and not unsubscribed
    def subscribed?
      !ended? && !unsubscribed?
    end

    # Checks if the `CampaignSubscription` is not subscribed by checking the presence of `unsubscribed_at`
    def unsubscribed?
      unsubscribed_at.present?
    end

    # Checks if the `CampaignSubscription` is ended by checking the presence of `ended_at`
    def ended?
      ended_at.present?
    end

    # Updates `ended_at` and runs `on_complete` callbacks
    def end!(reason = ::Caffeinate.config.default_ended_reason)
      raise ::Caffeinate::InvalidState, 'CampaignSubscription is already unsubscribed.' if unsubscribed?

      update!(ended_at: ::Caffeinate.config.time_now, ended_reason: reason)

      caffeinate_campaign.to_dripper.run_callbacks(:on_end, self)
      true
    end

    # Updates `ended_at` and runs `on_complete` callbacks
    def end(reason = ::Caffeinate.config.default_ended_reason)
      return false if unsubscribed?

      result = update(ended_at: ::Caffeinate.config.time_now, ended_reason: reason)

      caffeinate_campaign.to_dripper.run_callbacks(:on_end, self)
      result
    end

    # Updates `unsubscribed_at` and runs `on_subscribe` callbacks
    def unsubscribe!(reason = ::Caffeinate.config.default_unsubscribe_reason)
      raise ::Caffeinate::InvalidState, 'CampaignSubscription is already ended.' if ended?

      update!(unsubscribed_at: ::Caffeinate.config.time_now, unsubscribe_reason: reason)

      caffeinate_campaign.to_dripper.run_callbacks(:on_unsubscribe, self)
      true
    end

    # Updates `unsubscribed_at` and runs `on_subscribe` callbacks
    def unsubscribe(reason = ::Caffeinate.config.default_unsubscribe_reason)
      return false if ended?

      result = update(unsubscribed_at: ::Caffeinate.config.time_now, unsubscribe_reason: reason)

      caffeinate_campaign.to_dripper.run_callbacks(:on_unsubscribe, self)
      result
    end

    # Updates `unsubscribed_at` to nil and runs `on_subscribe` callbacks.
    # Use `force` to forcefully reset. Does not create the mailings.
    def resubscribe!(force = false)
      raise ::Caffeinate::InvalidState, 'CampaignSubscription is already ended.' if ended? && !force
      raise ::Caffeinate::InvalidState, 'CampaignSubscription is already unsubscribed.' if unsubscribed? && !force

      update!(unsubscribed_at: nil, resubscribed_at: ::Caffeinate.config.time_now)

      caffeinate_campaign.to_dripper.run_callbacks(:on_resubscribe, self)
      true
    end

    # Checks if the record is not new and if mailings are all gone.
    def completed?
      caffeinate_mailings.unsent.count.zero?
    end

    private

    def call_dripper_before_subscribe_blocks!
      caffeinate_campaign.to_dripper.run_callbacks(:before_subscribe, self)
    end

    def on_complete
      caffeinate_campaign.to_dripper.run_callbacks(:on_complete, self)
    end

    # Create mailings according to the drips registered in the Campaign
    def create_mailings!
      caffeinate_campaign.to_dripper.drips.each do |drip|
        mailing = Caffeinate::Mailing.new(caffeinate_campaign_subscription: self).from_drip(drip)
        mailing.save!
      end
      caffeinate_campaign.to_dripper.run_callbacks(:on_subscribe, self)
      true
    end

    # Sets a unique token
    def set_token!
      loop do
        self.token = SecureRandom.uuid
        break unless self.class.exists?(token: token)
      end
    end
  end
end
