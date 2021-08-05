require_relative '../funktor_config/boot'

$handler = Funktor::JobActivator.new

def call(event:, context:)
  $handler.call(event: event, context: context)
end

