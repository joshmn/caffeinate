# frozen_string_literal: true

module Caffeinate
  module Dripper
    # A collection of Drip objects for a `Caffeinate::Dripper`
    class DripCollection
      include Enumerable

      def initialize(dripper)
        @dripper = dripper
        @drips = {}
      end

      def for(action)
        @drips[action.to_sym]
      end

      # Register the drip
      def register(action, options, type = ::Caffeinate::Drip, &block)
        @drips[action.to_sym] = type.build(@dripper, action, options, &block)
      end

      def each(&block)
        @drips.each { |action_name, drip| block.call(action_name, drip) }
      end

      def values
        @drips.values
      end

      def size
        @drips.size
      end

      def [](val)
        @drips[val]
      end
    end
  end
end
