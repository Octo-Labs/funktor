# frozen_string_literal: true

require 'active_job'

module ActiveJob
  module QueueAdapters
    # == Funktor adapter for Active Job
    #
    # To use Funktor set the queue_adapter config to +:funktor+.
    #
    #   Rails.application.config.active_job.queue_adapter = :funktor
    class FunktorAdapter
      def enqueue(job) # :nodoc:
        JobWrapper.perform_async(job.serialize)
        # Funktor::Client does not support symbols as keys
        #job.provider_job_id = Funktor::Client.push \
          #"class"   => JobWrapper,
          #"wrapped" => job.class,
          #"queue"   => job.queue_name,
          #"args"    => [ job.serialize ]
      end

      def enqueue_at(job, timestamp) # :nodoc:
        job.provider_job_id = Funktor::Client.push \
          "class"   => JobWrapper,
          "wrapped" => job.class,
          "queue"   => job.queue_name,
          "args"    => [ job.serialize ],
          "at"      => timestamp
      end

      class JobWrapper #:nodoc:
        include Funktor::Worker

        def perform(job_data)
          Base.execute job_data.first
        end
      end
    end
  end

  class Base
    class_attribute :funktor_options_hash
    self.funktor_options_hash = {}

    def self.funktor_options(hsh)
      self.funktor_options_hash = self.funktor_options_hash.stringify_keys.merge(hsh.stringify_keys)
    end
  end
end
