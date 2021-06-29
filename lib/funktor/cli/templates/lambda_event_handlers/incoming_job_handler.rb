require 'funktor'

$handler = Funktor::IncomingJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

