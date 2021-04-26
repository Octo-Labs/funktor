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
  def build_payload(worker_class)
    { "body": worker_class.build_job_payload('fake-job-id', 0, {}).to_json }
  end

  def create_event(worker_classes = [HelloWorker, HelloWorker])
    event_data = {
      "Records": []
    }
    worker_classes.each do |worker_class|
      event_data[:Records].push(build_payload(worker_class))
    end
    event = Funktor.parse_json(event_data.to_json)
    return event
  end
end
