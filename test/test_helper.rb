ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelper
  # Integration-test helper: signs in as the given user by posting to the
  # real session endpoint, so tests exercise the same path a browser would.
  def sign_in_as(user, password: "password123")
    post session_url, params: { email: user.email, password: password }
  end
end

ActionDispatch::IntegrationTest.include SignInHelper
