require_relative "./work_queue"

module Funktor
  module CLI
    module Generate
      class Base < Thor
        register(WorkQueue, "work_queue", "work_queue NAME", "Generate new work queue and lambda handler")
      end
    end
  end
end


