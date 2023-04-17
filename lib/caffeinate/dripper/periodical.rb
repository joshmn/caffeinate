# frozen_string_literal: true

module Caffeinate
  module Dripper
    module Periodical
      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        def periodical(action_name, every:, start: -> { ::Caffeinate.config.time_now }, **options, &block)
          options[:start] = start
          options[:every] = every
          options[:until] ||= 5_000.years.from_now # can't call this out as a param above because `until` is a Ruby keyword

          drip(action_name, options, &block)

          after_send do |mailing, _message|
            if mailing.drip.action == action_name
              next_mailing = mailing.dup
              next_mailing.send_at = mailing.drip.send_at(mailing)
              next_mailing.save! unless mailing.drip.past_until?(next_mailing)
            end
          end
        end
      end
    end
  end
end
