# frozen_string_literal: true

require "bibframe_ruby"

module FixtureHelper
  def fixture_path(filename)
    File.join(File.expand_path("fixtures", __dir__), filename)
  end

  def read_fixture(filename)
    File.read(fixture_path(filename))
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include FixtureHelper

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
