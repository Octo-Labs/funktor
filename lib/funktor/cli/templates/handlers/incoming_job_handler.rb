require 'funktor'
require 'funktor/pro'

$handler = Funktor::Pro::IncomingJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

