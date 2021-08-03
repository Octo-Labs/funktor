require 'funktor/worker'
require 'funktor/fake_job_queue'

module Funktor
  module Worker
    def self.clear_all
      Funktor::FakeJobQueue.clear_all
    end
    module ClassMethods
      def jobs
        Funktor::FakeJobQueue.jobs[self.name]
      end

      def clear
        jobs.clear
      end

      def work_all_jobs
        while jobs.any?
          job_data = jobs.shift.with_indifferent_access
          worker = Object.const_get job_data[:worker]
          worker_params = job_data[:worker_params]
          worker.new.perform(worker_params)
        end
      end
    end
  end
  class Testing

    # TODO : We probably shouldn't use middleware for this. We should alter the behavior
    # of the JobPusher in the testing module isntead.
    def self.inline!(&block)
      unless block_given?
        raise "Funktor inline testing mode can only be called in block form."
      end
      Funktor.configure_job_pusher do |config|
        config.job_pusher_middleware do |chain|
          chain.add Funktor::InlineJobPusherMiddleware
        end
      end
      yield
      Funktor.configure_job_pusher do |config|
        config.job_pusher_middleware do |chain|
          chain.remove Funktor::InlineJobPusherMiddleware
        end
      end
    end
    def self.fake!(&block)
      if block_given?
        Funktor.configure_job_pusher do |config|
          config.job_pusher_middleware do |chain|
            chain.add Funktor::FakeJobPusherMiddleware
          end
        end
        yield
        Funktor.configure_job_pusher do |config|
          config.job_pusher_middleware do |chain|
            chain.remove Funktor::FakeJobPusherMiddleware
          end
        end
      else
        Funktor.configure_job_pusher do |config|
          config.job_pusher_middleware do |chain|
            chain.add Funktor::FakeJobPusherMiddleware
          end
        end
      end
    end
    def self.disable!
      Funktor.configure_job_pusher do |config|
        config.job_pusher_middleware do |chain|
          chain.remove Funktor::FakeJobPusherMiddleware
        end
      end
    end
  end

  class InlineJobPusherMiddleware
    def call(payload)
      payload = payload.with_indifferent_access
      worker = Object.const_get payload["worker"]
      worker.new.perform(*payload["worker_params"])
    end
  end

  class FakeJobPusherMiddleware
    def call(payload)
      Funktor::FakeJobQueue.push(payload)
    end
  end
end
