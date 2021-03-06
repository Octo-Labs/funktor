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

class NoRetryWorker
  include Funktor::Worker
  funktor_options retry: 0
  def perform(param_one = nil, param_two = nil)
    raise "hell"
  end
end

class CustomRetryWorker
  include Funktor::Worker
  funktor_retry_in do |count|
    8
  end

  def perform(param_one = nil, param_two = nil)
    raise "hell"
  end
end

module JobSpecHelpers
  def build_payload(worker_class, delay = 0)
    job_time = Time.now.utc + delay
    payload = worker_class.build_job_payload(job_time, 1, 'two')
    payload["job_id"] = SecureRandom.uuid
    { "body": Funktor.dump_json(payload) }
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
