RSpec.configure do |config|
  config.before(:each) do
    Caffeinate.dripper_collection.clear_cache!
  end
end
