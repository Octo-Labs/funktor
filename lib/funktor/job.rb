module Funktor
  class Job
    attr_accessor :job_string
    attr_accessor :job_data
    def initialize(job_string)
      @job_string = job_string
    end

    def job_data
      @job_data ||= Funktor.parse_json(job_string)
    end

    def queue
      job_data["queue"]
    end

    def worker_class_name
      job_data["worker"]
    end

    def job_id
      job_data["job_id"]
    end

    def shard
      # TODO - Should the number of shards be configurable?
      job_data["job_id"].hash % 64
    end

    def worker_params
      job_data["worker_params"]
    end

    def retries
      job_data["retries"] || 0
    end

    def is_retry?
      job_data["retries"].present?
    end

    def retries=(retries)
      job_data["retries"] = retries
    end

    def perform_at
      if job_data["perform_at"].present?
        job_data["perform_at"].is_a?(Time) ? job_data["perform_at"] : Time.parse(job_data["perform_at"])
      else
        Time.now.utc
      end
    end

    def delay
      (perform_at - Time.now.utc).to_i
    end

    def delay=(delay)
      job_data["perform_at"] = Time.now.utc + delay
    end

    def error_class
      job_data["error_class"]
    end

    def error_message
      job_data["error_message"]
    end

    def error_backtrace
      job_data["error_backtrace"]
    end

    def error=(error)
      # TODO We should maybe compress this?
      job_data["error_class"] = error.class.name
      job_data["error_message"] = error.message
      job_data["error_backtrace"] = Funktor.dump_json(error.backtrace)
    end

    def execute
      worker_class.new.perform(*worker_params)
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
      Funktor.dump_json(job_data)
    end

    def retry_limit
      25
    end

    def can_retry
      self.retries < retry_limit
    end

    def retry_queue_url
      worker_class&.custom_queue_url || ENV['FUNKTOR_INCOMING_JOB_QUEUE']
    end
  end
end
