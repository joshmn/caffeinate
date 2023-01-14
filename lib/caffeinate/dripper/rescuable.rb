# frozen_string_literal: true

module Caffeinate
  module Dripper
    module Rescuable
      def self.included(klass)
        klass.include ::ActiveSupport::Rescuable
        klass.extend ClassMethods
      end

      module ClassMethods
        def deliver!(mailing)
          begin
            super
          rescue Exception => exception
            if self.rescue_with_handler(exception, object: mailing)
              return
            end
            raise
          end
        end
      end
    end
  end
end
