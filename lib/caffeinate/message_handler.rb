module Caffeinate
  # Delegates methods to a Caffeinate::Action class
  class MessageHandler < Delegator
    def initialize(action_class, action, message) # :nodoc:
      @action_class, @action, @message = action_class, action, message
    end

    def __getobj__
      processed_action
    end

    private

    def processed_action
      @processed_action ||= @action_class.new.tap do |action_object|
        action_object.process @action, @message
      end
    end
  end
end
