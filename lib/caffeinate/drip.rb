# frozen_string_literal: true

require 'caffeinate/drip_evaluator'
require 'caffeinate/schedule_evaluator'

module Caffeinate
  # A Drip object
  #
  # Handles the block and provides convenience methods for the drip
  class Drip
    ALL_DRIP_OPTIONS = [:mailer_class, :mailer, :start, :using, :step]
    VALID_DRIP_OPTIONS = ALL_DRIP_OPTIONS + [:delay, :start, :at, :on].freeze

    class << self
      def build(dripper, action, options, &block)
        validate_drip_options(dripper, action, options)

        new(dripper, action, options, &block)
      end

      private

      def validate_drip_options(dripper, action, options)
        options = normalize_options(dripper, options)

        if options[:mailer_class].nil?
          raise ArgumentError, "You must define :mailer_class or :mailer in the options for #{action.inspect} on #{dripper.inspect}"
        end

        if options[:every].nil? && options[:delay].nil? && options[:on].nil?
          raise ArgumentError, "You must define :delay or :on or :every in the options for #{action.inspect} on #{dripper.inspect}"
        end

        options
      end

      def normalize_options(dripper, options)
        options[:mailer_class] ||= options[:mailer] || dripper.defaults[:mailer_class]
        options[:using] ||= dripper.defaults[:using]
        options[:step] ||= dripper.drips.size + 1

        options
      end
    end

    attr_reader :dripper, :action, :options, :block

    def initialize(dripper, action, options, &block)
      @dripper = dripper
      @action = action
      @options = options
      @block = block
    end

    # If the associated ActionMailer uses `ActionMailer::Parameterized` initialization instead of argument-based initialization
    def parameterized?
      options[:using] == :parameterized
    end

    def send_at(mailing = nil)
      ::Caffeinate::ScheduleEvaluator.call(self, mailing)
    end

    # Checks if the drip is enabled
    #
    # This is kind of messy and could use some love.
    # todo: better.
    def enabled?(mailing)
      catch(:abort) do
        if dripper.run_callbacks(:before_drip, self, mailing)
          return DripEvaluator.new(mailing).call(&@block)
        else
          return false
        end
      end
      false
    end

    def type
      name = self.class.name.delete_suffix("Drip").presence || "Drip"

      ActiveSupport::StringInquirer.new(name)
    end
  end
end
