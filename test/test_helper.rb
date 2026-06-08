ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    # Threshold raised to 200 — thread-based parallelism causes PG FK deadlocks
    # when fixture loading concurrency is high. Keep single-process until the
    # suite is large enough to justify it.
    parallelize(workers: :number_of_processors, with: :threads, threshold: 200)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
