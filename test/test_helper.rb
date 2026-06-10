ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/stripe_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    # Threshold kept high — thread-based parallelism causes PG FK deadlocks on
    # local Postgres when fixture loading concurrency is high. Raise when the
    # suite grows large enough to justify tuning max_connections instead.
    parallelize(workers: :number_of_processors, with: :threads, threshold: 1200)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
