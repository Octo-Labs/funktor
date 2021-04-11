module Funktor
  module Aws
    module Sqs
      class Record
        attr_accessor :record_data
        attr_accessor :job
        def initialize(record_data)
          @record_data = record_data
          @job = Funktor::Job.new(record_data["body"])
        end
      end
    end
  end
end
