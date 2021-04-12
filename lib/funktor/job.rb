module Funktor
  class Job
    attr_accessor :job_string
    def initialize(job_string)
      @job_string = job_string
      @job_data = JSON.parse(job_string)
    end

    def worker_class_name
      @job_data["worker"]
    end

    def worker_params
      @job_data["worker_params"]
    end

    def retries
      @job_data["retries"] || 0
    end

    def retries=(retries)
      @job_data["retries"] = retries
    end

    def delay
      @job_data["delay"]
    end

    def delay=(delay)
      @job_data["delay"] = delay
    end

    def execute
      worker_class.new.perform(worker_params)
    end

    def worker_class
      @klass ||= Object.const_get worker_class_name
    end

    def increment_retries
      self.retries ||= 0
      self.retries += 1
      self.delay = seconds_to_delay(retries)
    end

    # delayed_job and sidekiq use the same basic formula
    def seconds_to_delay(count)
      (count**4) + 15 + (rand(30) * (count + 1))
    end

    def to_json(arg = nil)
      @job_data.to_json
    end

    def retry_limit
      25
    end

    def can_retry
      self.retries < retry_limit
    end

    def retry_queue_url
      worker_class&.custom_queue_url || ENV['FUNKTOR_INCOMING_QUEUE_URL']
    end
  end
end
