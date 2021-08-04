# simplecov has to come first
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

# Now the normal stuff
require "bundler/setup"
require 'webmock/rspec'

require "funktor"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Since we log to stdout things get noisy in tests, so we silence
# that. If you need to see output for debugging or something you
# can temporarilly disable this next line.
Funktor.logger = Logger.new(nil)
