require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Use S3 when AWS_BUCKET is set; fall back to local disk otherwise.
  config.active_storage.service = ENV["AWS_BUCKET"].present? ? :amazon : :local

  # Railway terminates SSL at the edge — trust it and enforce HTTPS.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  config.action_mailer.default_url_options = { host: ENV.fetch("RAILS_HOST", "localhost") }

  # SMTP is enabled when SMTP_ADDRESS is set as a Railway env var.
  # Required vars: SMTP_ADDRESS, SMTP_USERNAME, SMTP_PASSWORD
  # Optional vars: SMTP_PORT (default 587), ACTION_MAILER_FROM
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", "587").to_i,
      user_name: ENV.fetch("SMTP_USERNAME", nil),
      password: ENV.fetch("SMTP_PASSWORD", nil),
      authentication: :plain,
      enable_starttls_auto: true
    }
    config.action_mailer.default_options = {
      from: ENV.fetch("ACTION_MAILER_FROM", "noreply@#{ENV.fetch("RAILS_HOST", "localhost")}")
    }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Allow Railway's auto-assigned domain and any custom domain set via RAILS_HOST.
  # Add custom domains to RAILS_ALLOWED_HOSTS (comma-separated) in the Railway env vars.
  config.hosts = [
    /.*\.up\.railway\.app/,
    /.*\.railway\.app/,
    *ENV.fetch("RAILS_ALLOWED_HOSTS", "").split(",").map(&:strip).reject(&:empty?)
  ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
