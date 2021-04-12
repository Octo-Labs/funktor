require_relative './record'
module Funktor
  module Aws
    module Sqs
      class Event
        attr_accessor :event_data
        def initialize(event_data)
          @event_data = event_data
        end

        def records
          @records ||= @event_data["Records"].map{|record_data| Funktor::Aws::Sqs::Record.new(record_data) }
        end

        def jobs
          records.map(&:job)
        end
      end
    end
  end
end
