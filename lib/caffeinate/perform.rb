module Caffeinate
  module Perform
    def perform!
      if Caffeinate.config.enabled_drippers.nil?
        Caffeinate.dripper_collection.each do |_, dripper|
          dripper.constantize.perform!
        end
      else
        Caffeinate.config.enabled_drippers.each do |dripper|
          dripper.to_s.constantize.perform!
        end
      end

      true
    end
  end
end
