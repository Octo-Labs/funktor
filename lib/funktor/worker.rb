require 'securerandom'
require "active_support"
require 'funktor/worker/funktor_options'

module Funktor
  class DelayTooLongError < StandardError; end
end

module Funktor::Worker
  def self.included(base)
    base.extend ClassMethods
    base.include(Funktor::Worker::FunktorOptions)
  end

  module ClassMethods

    def perform_async(*worker_params)
      self.perform_in(0, *worker_params)
    end

    def perform_at(job_time, *worker_params)
      self.push(job_time, *worker_params)
    end

    def perform_in(delay, *worker_params)
      job_time = Time.now.utc + delay
      self.perform_at(job_time, *worker_params)
    end

    def push(job_time, *worker_params)
      payload = build_job_payload(job_time, *worker_params)
      Funktor.job_pusher.push(payload)
    end

    def build_job_payload(job_time, *worker_params)
      {
        worker: self.name,
        worker_params: worker_params,
        queue: self.work_queue,
        incoming_job_queue_url: self.queue_url,
        perform_at: job_time.utc,
        funktor_options: get_funktor_options
      }
    end
  end
end
