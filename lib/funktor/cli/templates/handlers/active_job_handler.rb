require 'funktor'

# Bundler is hard to make work because AWS includes some gems in the basic ruby runtime.
# We're probably going to need to use containers...
#require "rubygems"
#require "bundler/setup"
#Bundler.require(:default)

# TODO : Ideally this wouldn't be needed
require_relative '../workers/hello_worker'

$handler = Funktor::ActiveJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

