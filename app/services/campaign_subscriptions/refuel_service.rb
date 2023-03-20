module CampaignSubscriptions
  class RefuelService

    def initialize(campaign_subscription, offset: :created_at)
      raise ArgumentError, "must be either :current or :created_at" unless [:created_at, :current].include?(offset.to_sym)

      @campaign_subscription = campaign_subscription
      @campaign = @campaign_subscription.caffeinate_campaign
      @offset = offset.to_sym
    end

    def call
      mailings = []

      @campaign.to_dripper.drips.each do |drip|
        mailing = Caffeinate::Mailing.find_or_initialize_from_drip(@campaign_subscription, drip)
        if mailing.new_record?
          mailing.send_at = drip.send_at(@campaign_subscription)
          if @offset == :created_at
            mailing.send_at + (Caffeinate.config.now.call - @campaign_subscription.created_at)
          elsif @offset == :current
            # do nothing on purpose!
          end

          mailing.save!
          mailings << mailing
        end
      end

      mailings
    end
  end
end
