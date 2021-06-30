# For this handler we don't need to know about your app, or any of the other gems,
# so instead of doing `require_relative '../config/boog'` we just manually require
# the one gem that we do need.
require 'funktor'

$handler = Funktor::IncomingJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

