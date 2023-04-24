require 'caffeinate/message_handler'

module Caffeinate
  # Allows you to use a PORO for a drip; acts just like ActionMailer::Base
  #
  # Usage:
  #   class TextAction < Caffeinate::Action
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
  #
  # usage:
  #
  #   class TextAction < Caffeinate::Action
  #     class Envelope(user)
  #       @sms = SMS.new(to: user.phone_number)
  #     end
  #
  #     def deliver!(action)
  #       # action will be the instantiated TextAction object
  #       # and you can access action.action_name, etc.
  #
  #       erb = ERB.new(File.read(Rails.root + "app/views/cool_one_off_action/#{action_object.action_name}.text.erb"))
  #       # ...
  #       @sms.send!
  #     end
  #
  #     def welcome(mailing)
  #       Envelope.new(mailing.subscriber)
  #     end
  #   end
  class Action
    attr_accessor :caffeinate_mailing
    attr_accessor :perform_deliveries
    attr_reader :action_name

    class DeliveryMethod
      def deliver!(action)
        # implement this if you want to
      end
    end

    def initialize
      @delivery_method = DeliveryMethod.new
      @perform_deliveries = true # will only be false if interceptors set it so
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

    def process(action_name, action_args)
      @action_name = action_name # pass-through for #send
      @action_args = action_args # pass-through for #send
      self.caffeinate_mailing = action_args if action_args.is_a?(Caffeinate::Mailing)
    end

    # Follows Mail::Message
    def deliver
      inform_interceptors
      do_delivery
      inform_observers
      self
    end

    # This method bypasses checking perform_deliveries and raise_delivery_errors,
    # so use with caution.
    #
    # It still however fires off the interceptors and calls the observers callbacks if they are defined.
    #
    # Returns self
    def deliver!
      inform_interceptors
      handled = send(@action_name, @action_args)
      if handled.respond_to?(:deliver!) && !handled.is_a?(Caffeinate::Mailing)
        handled.deliver!(self)
      end
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
          handled = send(@action_name, @action_args)
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
