require 'funktor/worker'
require 'funktor/job_pusher'
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
    class << self
      attr_accessor :mode

      def inline?
        mode == :inline
      end

      def fake?
        mode == :fake
      end

      def inline!(&block)
        unless block_given?
          raise "Funktor inline testing mode can only be called in block form."
        end
        set_mode(:inline, &block)
      end

      def fake!(&block)
        set_mode(:fake, &block)
      end

      def disable!
        set_mode(:disabled)
      end

      def set_mode(new_mode, &block)
        if block_given?
          original_mode = mode
          self.mode = new_mode
          begin
            yield
          ensure
            self.mode = original_mode
          end
        else
          self.mode = new_mode
        end
      end
    end
  end

  module TestingPusher
    def push(payload)
      if Funktor::Testing.inline?
        Funktor.job_pusher_middleware.invoke(payload) do
          payload = payload.with_indifferent_access
          worker = Object.const_get payload["worker"]
          worker.new.perform(*payload["worker_params"])
        end
      elsif Funktor::Testing.fake?
        Funktor.job_pusher_middleware.invoke(payload) do
          Funktor::FakeJobQueue.push(payload)
        end
      else
        super
      end
    end
  end

  Funktor::JobPusher.prepend TestingPusher

end
