require 'funktor/worker'

class HelloWorker
  include Funktor::Worker
  def perform(params_one = nil, param_two = nil)
    Funktor.logger.debug "hello"
  end
end

class FailWorker
  include Funktor::Worker
  def perform(param_one = nil, param_two = nil)
    raise "hell"
  end
end

module JobSpecHelpers
  def build_payload(worker_class, delay = 0)
    job_time = Time.now.utc + delay
    { "body": Funktor.dump_json(worker_class.build_job_payload(job_time, 1, 'two')) }
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
