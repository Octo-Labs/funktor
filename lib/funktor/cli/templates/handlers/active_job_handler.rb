require 'funktor'
require 'funktor/pro'

# Bundler is hard to make work because AWS includes some gems in the basic ruby runtime.
# We're probably going to need to use containers...
#require "rubygems"
#require "bundler/setup"
#Bundler.require(:default)

require_relative '../app/lambda_workers/hello_worker'
require_relative '../app/lambda_workers/hello_later_worker'

$handler = Funktor::ActiveJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

