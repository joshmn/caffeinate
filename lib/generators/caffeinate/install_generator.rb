# frozen_string_literal: true

module Caffeinate
  module Generators
    # Installs Caffeinate
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates a Caffeinate initializer and copies migrations to your application.'

      class_option :uuid, type: :boolean, default: false,
        desc: 'Use UUID primary keys (requires PostgreSQL with pgcrypto)'

      class_option :primary_key_type, type: :string, default: nil,
        desc: 'Primary key type: uuid, bigint, or integer (default)'

      def primary_key_type
        return :uuid if options[:uuid]
        return options[:primary_key_type].to_sym if options[:primary_key_type]
        nil
      end

      def primary_key_option
        return '' unless primary_key_type
        ", id: :#{primary_key_type}"
      end

      def foreign_key_type
        return '' unless primary_key_type
        ", type: :#{primary_key_type}"
      end

      def column_type_for_polymorphic
        case primary_key_type
        when :uuid then :uuid
        when :bigint then :bigint
        else :integer
        end
      end

      def enable_pgcrypto?
        primary_key_type == :uuid
      end

      # :nodoc:
      def copy_initializer
        template 'caffeinate.rb', 'config/initializers/caffeinate.rb'
      end

      # :nodoc:
      def copy_application_campaign
        template 'application_dripper.rb', 'app/drippers/application_dripper.rb'
      end

      def install_routes
        inject_into_file 'config/routes.rb', "\n  mount ::Caffeinate::Engine => '/caffeinate'", after: /Rails.application.routes.draw do/
      end

      # :nodoc:
      def self.next_migration_number(_path)
        if @prev_migration_nr
          @prev_migration_nr += 1
        else
          @prev_migration_nr = Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
        end
        @prev_migration_nr.to_s
      end

      def migration_version
        if rails5_and_up?
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

      def rails5_and_up?
        Rails::VERSION::MAJOR >= 5
      end

      # :nodoc:
      def copy_migrations
        template 'migrations/create_caffeinate_campaigns.rb', "db/migrate/#{self.class.next_migration_number("")}_create_caffeinate_campaigns.rb"
        template 'migrations/create_caffeinate_campaign_subscriptions.rb', "db/migrate/#{self.class.next_migration_number("")}_create_caffeinate_campaign_subscriptions.rb"
        template 'migrations/create_caffeinate_mailings.rb', "db/migrate/#{self.class.next_migration_number("")}_create_caffeinate_mailings.rb"
      end
    end
  end
end
