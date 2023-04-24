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
          periodical_drip(action_name, **options, &block)

          after_send do |mailing, _message|
            make_email = -> {
              next_mailing = mailing.dup
              next_mailing.send_at = mailing.drip.send_at(mailing)
              next_mailing.save!
            }
            if mailing.drip.action == action_name
              if condition = mailing.drip.options[:if]
                if OptionEvaluator.new(condition, mailing.drip, mailing).call
                  make_email.call
                end
              else
                make_email.call
              end
            end
          end
        end
      end
    end
  end
end
