# frozen_string_literal: true

require "sidekiq"
require "sidekiq-cron"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  cron_file = Rails.root.join("config/sidekiq_cron.yml")
  if cron_file.exist?
    schedule = YAML.load_file(cron_file) || {}
    Sidekiq::Cron::Job.load_from_hash!(schedule) if schedule.any?
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
