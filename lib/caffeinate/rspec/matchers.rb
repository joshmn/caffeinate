require 'caffeinate/rspec/matchers/be_subscribed_to_caffeinate_campaign'
require 'caffeinate/rspec/matchers/subscribe_to_caffeinate_campaign'
require 'caffeinate/rspec/matchers/unsubscribe_from_caffeinate_campaign'

RSpec.configure do |config|
  config.include Caffeinate::RSpec::Matchers
end
