require 'funktor/worker'

class TestWorker
  include Funktor::Worker
  def perform(params)
    puts "hello"
  end
end

class FailOnceWorker
  include Funktor::Worker
  def perform(params)
    raise "hell"
  end
end

module JobSpecHelpers

  def test_worker_payload
    TestWorker.build_job_payload({}, 'fake-id', 0)
  end

  def create_event
    event = JSON.parse({
      "Records": [
        { "body": test_worker_payload.to_json },
        { "body": test_worker_payload.to_json }
      ]
    }.to_json)
    return event
  end
end
