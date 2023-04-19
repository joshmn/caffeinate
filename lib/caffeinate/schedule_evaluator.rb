module Caffeinate
  class OptionEvaluator
    def initialize(thing, drip, mailing)
      @thing = thing
      @drip = drip
      @mailing = mailing
    end

    def call
      if @thing.is_a?(Symbol)
        @drip.dripper.new.send(@thing, @drip, @mailing)
      elsif @thing.is_a?(Proc)
        @mailing.instance_exec(&@thing)
      elsif @thing.is_a?(String)
        Time.parse(@thing)
      else
        @thing
      end
    end
  end

  class ScheduleEvaluator
    def self.call(drip, mailing)
      new(drip, mailing).call
    end

    attr_reader :mailing
    def initialize(drip, mailing)
      @drip = drip
      @mailing = mailing
    end

    # todo: test this decision tree.
    def call
      if periodical?
        start = OptionEvaluator.new(options[:start], self, mailing).call
        start += OptionEvaluator.new(options[:every], self, mailing).call if mailing.caffeinate_campaign_subscription.caffeinate_mailings.size.positive?
        date = start
      elsif options[:on]
        date = OptionEvaluator.new(options[:on], self, mailing).call
      else
        date = OptionEvaluator.new(options[:delay], self, mailing).call
      end

      if date.respond_to?(:from_now)
        date = date.from_now
      end

      if options[:at]
        time = OptionEvaluator.new(options[:at], self, mailing).call
        return date.change(hour: time.hour, min: time.min, sec: time.sec)
      end

      date
    end

    def respond_to_missing?(name, include_private = false)
      @drip.respond_to?(name, include_private)
    end

    def method_missing(method, *args, &block)
      @drip.send(method, *args, &block)
    end

    private

    def periodical?
      @drip.type.periodical?
    end
  end
end
