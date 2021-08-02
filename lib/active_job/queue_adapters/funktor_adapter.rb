# frozen_string_literal: true

require 'active_job'
require "funktor/worker/funktor_options"

module ActiveJob
  module QueueAdapters
    # == Funktor adapter for Active Job
    #
    # To use Funktor set the queue_adapter config to +:funktor+.
    #
    #   Rails.application.config.active_job.queue_adapter = :funktor
    class FunktorAdapter
      def enqueue(job) # :nodoc:
        job.provider_job_id = Funktor.job_pusher.push({
          "worker"  => JobWrapper.to_s,
          "wrapped" => job.class,
          "queue"   => job.class.work_queue,
          "delay"   => 0,
          "worker_params"    => job.serialize
        })
      end

      def enqueue_at(job, timestamp) # :nodoc:
        delay = (Time.at(timestamp).utc - Time.now.utc).round
        if delay < 0
          delay = 0
        end
        job.provider_job_id = Funktor.job_pusher.push({
          "worker"  => JobWrapper.to_s,
          "wrapped" => job.class,
          "queue"   => job.class.work_queue,
          "delay"   => delay,
          "worker_params"    => job.serialize
        })
      end

      class JobWrapper #:nodoc:
        include Funktor::Worker

        def perform(job_data)
          puts "job_data = #{job_data.class}"
          puts job_data
          Base.execute job_data
        end
      end
    end
  end

  class Base
    include Funktor::Worker::FunktorOptions
  end
end
