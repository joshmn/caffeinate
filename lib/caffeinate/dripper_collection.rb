# frozen_string_literal: true

module Caffeinate
  class DripperCollection
    delegate :each, to: :@registry

    def initialize
      @registry = {}
    end

    def register(name, klass)
      @registry[name.to_sym] = klass
    end

    def resolve(campaign)
      @registry[campaign.slug.to_sym].constantize
    end

    def drippers
      @registry.values
    end

    # Caffeinate maintains a couple of class-variables under the hood
    # that don't get reset between specs (while the db records they cache do
    # get truncated). This resets the appropriate class-variables between specs
    def clear_cache!
      drippers.each do |dripper|
        dripper.safe_constantize.class_eval { @caffeinate_campaign = nil }
      end
    end

    def clear!
      @registry = {}
    end
  end
end
