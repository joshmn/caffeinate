# frozen_string_literal: true

require 'caffeinate/drip_evaluator'
require 'caffeinate/schedule_evaluator'

module Caffeinate
  # A PeriodicalDrip object
  #
  # Handles the block and provides convenience methods for the drip
  class PeriodicalDrip < Drip
    VALID_DRIP_OPTIONS = ALL_DRIP_OPTIONS + [:every, :until]

    class << self
      private def validate_drip_options(dripper, action, options)
        super
      end

      def assert_options(options)
        options.assert_valid_keys(*VALID_DRIP_OPTIONS)
      end

      def normalize_options(dripper, options)
        options[:mailer_class] ||= options[:mailer] || dripper.defaults[:mailer_class]
        options[:using] ||= dripper.defaults[:using]
        options[:step] ||= dripper.drips.size + 1

        unless options.key?(:every)
          raise "Periodical drips must have an `every` option."
        end

        options
      end
    end

    def every
      options[:every]
    end
  end
end
