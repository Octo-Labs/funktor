require_relative '../config/boot'

$handler = Funktor::ActiveJobHandler.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

