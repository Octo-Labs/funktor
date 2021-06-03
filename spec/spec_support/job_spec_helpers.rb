require 'funktor/worker'

class HelloWorker
  include Funktor::Worker
  def perform(params)
    puts "hello"
  end
end

class FailWorker
  include Funktor::Worker
  def perform(params)
    raise "hell"
  end
end

module JobSpecHelpers
  def build_payload(worker_class, delay = 0)
    { "body": Funktor.dump_json(worker_class.build_job_payload('fake-job-id', delay, {})) }
  end

  def create_event(worker_classes = [HelloWorker, HelloWorker], delay = 0)
    event_data = {
      "Records": []
    }
    worker_classes.each do |worker_class|
      event_data[:Records].push(build_payload(worker_class, delay))
    end
    event = Funktor.parse_json(Funktor.dump_json(event_data))
    return event
  end
end
