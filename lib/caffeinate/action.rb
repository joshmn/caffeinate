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
  class Action
    attr_accessor :caffeinate_mailing
    attr_accessor :perform_deliveries

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
      ::Caffeinate::ActionMailer::Interceptor.delivering_email(self)
    end

    def deliver
      if self.perform_deliveries
        send(@action_name, caffeinate_mailing)
        ::Caffeinate::ActionMailer::Observer.delivered_email(self)
      end
    end
  end
end
