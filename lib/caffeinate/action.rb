require 'caffeinate/message_handler'

module Caffeinate
  # Allows you to use a PORO for a drip; acts just like ActionMailer::Base
  #
  # Usage:
  #   class TextHandler < Caffeinate::Action
  #     def welcome(mailing)
  #       user = mailing.subscriber
  #       HTTParty.post("...") # ...
  #     end
  #   end
  #
  # In the future (when?), "mailing" objects will become "messages".
  #
  # Optionally, you can use the method for setup and return an object that implements `#deliver!`
  # and that will be invoked.
  class Action
    attr_accessor :caffeinate_mailing
    attr_accessor :perform_deliveries

    class DeliveryMethod
      def deliver!(action)
        # implement this if you want to
      end
    end

    def initialize
      @delivery_method = DeliveryMethod.new
    end

    class << self
      def action_methods
        @action_methods ||= begin
                              methods = (public_instance_methods(true) -
                                internal_methods +
                                public_instance_methods(false))
                              methods.map!(&:to_s)
                              methods.to_set
                            end
      end

      def internal_methods
        controller = self

        controller = controller.superclass until controller.abstract?
        controller.public_instance_methods(true)
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          ::Caffeinate::MessageHandler.new(self, method_name, *args)
        else
          super
        end
      end
      ruby2_keywords(:method_missing)

      def respond_to_missing?(method, include_all = false)
        action_methods.include?(method.to_s) || super
      end

      def abstract?
        true
      end
    end

    def process(action_name, mailing)
      @action_name = action_name
      self.caffeinate_mailing = mailing
    end

    # Follows Mail::Message
    def deliver
      inform_interceptors
      do_delivery
      inform_observers
      self
    end

    private

    def inform_interceptors
      ::Caffeinate::ActionMailer::Interceptor.delivering_email(self)
    end

    def inform_observers
      ::Caffeinate::ActionMailer::Observer.delivered_email(self)
    end

    # In your action's method (@action_name), if you return an object that responds to `deliver!`
    # we'll invoke it. This is useful for doing setup in the method and then firing it later.
    def do_delivery
      begin
        if perform_deliveries
          handled = send(@action_name, caffeinate_mailing)
          if handled.respond_to?(:deliver!) && !handled.is_a?(Caffeinate::Mailing)
            handled.deliver!(self)
          end
        end
      rescue => e
        raise e
      end
    end
  end
end
