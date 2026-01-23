# frozen_string_literal: true

module ConfigurableSchema
  def self.primary_key_type
    case ENV['CAFFEINATE_PRIMARY_KEY_TYPE']
    when 'uuid' then :uuid
    when 'bigint' then :bigint
    else nil
    end
  end

  def self.setup!
    return unless primary_key_type

    ActiveRecord::Migration.suppress_messages do
      recreate_tables!
    end
    Caffeinate.dripper_collection.clear_cache!
  end

  def self.recreate_tables!
    drop_tables!
    create_tables!
  end

  def self.drop_tables!
    %i[caffeinate_mailings caffeinate_campaign_subscriptions caffeinate_campaigns users companies].each do |table|
      ActiveRecord::Base.connection.drop_table(table) if ActiveRecord::Base.connection.table_exists?(table)
    end
  end

  def self.create_tables!
    pk_type = primary_key_type
    col_type = primary_key_type || :integer

    if pk_type == :uuid
      ActiveRecord::Base.connection.enable_extension('pgcrypto')
    end
    ActiveRecord::Base.connection.execute("SET timezone = 'UTC'") if pk_type

    ActiveRecord::Base.connection.create_table(:companies, id: pk_type || :primary_key) do |t|
      t.timestamps
    end

    ActiveRecord::Base.connection.create_table(:users, id: pk_type || :primary_key) do |t|
      t.string :email
      t.send(col_type, :company_id)
      t.timestamps
    end

    ActiveRecord::Base.connection.create_table(:caffeinate_campaigns, id: pk_type || :primary_key) do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    ActiveRecord::Base.connection.add_index(:caffeinate_campaigns, :slug, unique: true)

    ActiveRecord::Base.connection.create_table(:caffeinate_campaign_subscriptions, id: pk_type || :primary_key) do |t|
      t.references :caffeinate_campaign, null: false, type: col_type, foreign_key: true
      t.string :subscriber_type, null: false
      t.send(col_type, :subscriber_id, null: false)
      t.string :user_type
      t.send(col_type, :user_id)
      t.string :token, null: false
      t.datetime :ended_at
      t.string :ended_reason
      t.datetime :resubscribed_at
      t.datetime :unsubscribed_at
      t.string :unsubscribe_reason
      t.timestamps
    end
    ActiveRecord::Base.connection.add_index(:caffeinate_campaign_subscriptions, :token, unique: true)

    ActiveRecord::Base.connection.create_table(:caffeinate_mailings, id: pk_type || :primary_key) do |t|
      t.references :caffeinate_campaign_subscription, null: false, type: col_type, foreign_key: true
      t.datetime :send_at, null: false
      t.datetime :sent_at
      t.datetime :skipped_at
      t.string :mailer_class, null: false
      t.string :mailer_action, null: false
      t.timestamps
    end
  end
end
