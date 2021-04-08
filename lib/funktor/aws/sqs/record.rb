module Funktor
  module Aws
    module Sqs
      class Record
        attr_accessor :record_data
        def initialize(record_data)
          @record_data = record_data
        end
      end
    end
  end
end
