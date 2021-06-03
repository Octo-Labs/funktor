require 'securerandom'
require 'aws-sdk-sqs'
require "active_support"

module Funktor
  class DelayTooLongError < StandardError; end
end

module Funktor::Worker
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      cattr_accessor :funktor_options_hash
      #alias_method :perform_later, :perform_async
    end
  end

  module ClassMethods
    def funktor_options(options = {})
      self.funktor_options_hash = options
    end

    def get_funktor_options
      self.funktor_options_hash || {}
    end

    def custom_queue_url
      get_funktor_options[:queue_url]
    end

    def queue_url
      # TODO : Should this default to FUNKTOR_ACTIVE_JOB_QUEUE?
      # Depends how e handle this in pro...?
      custom_queue_url || ENV['FUNKTOR_INCOMING_JOB_QUEUE']
    end

    def perform_async(*worker_params)
      self.perform_in(0, *worker_params)
    end

    def perform_at(time, *worker_params)
      delay = (time.utc - Time.now.utc).round
      if delay < 0
        delay = 0
      end
      self.perform_in(delay, *worker_params)
    end

    def perform_in(delay, *worker_params)
      if delay > max_delay
        raise Funktor::DelayTooLongError.new("The delay can't be longer than #{max_delay} seconds. This is a limitation of SQS. Funktor Pro has mechanisms to work around this limitation.")
      end
      self.push_to_incoming_job_queue(delay, *worker_params)
    end

    def push_to_incoming_job_queue(delay, *worker_params)
      job_id = SecureRandom.uuid
      payload = build_job_payload(job_id, delay, *worker_params)

      Funktor.job_pusher_middleware.invoke(self, payload) do
        client.send_message({
          queue_url: queue_url,
          message_body: Funktor.dump_json(payload)
        })
      end
    end

    def max_delay
      900
    end

    def client
      @client ||= Aws::SQS::Client.new
    end

    def build_job_payload(job_id, delay, *worker_params)
      {
        worker: self.name,
        worker_params: worker_params,
        job_id: job_id,
        delay: delay,
        funktor_options: get_funktor_options
      }
    end
  end
end
