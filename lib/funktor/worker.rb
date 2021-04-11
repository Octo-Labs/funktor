require 'securerandom'
require 'aws-sdk-sqs'
require "active_support"


module Funktor::Worker
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      cattr_accessor :custom_queue_url
      #alias_method :perform_later, :perform_async
    end
  end

  module ClassMethods
    def funktor_queue_url(queue_url)
      self.custom_queue_url = queue_url
    end

    def queue_url
      custom_queue_url || ENV['FUNKTOR_INCOMING_QUEUE_URL']
    end

    def perform_async(worker_params)
      self.perform_in(0, worker_params)
    end

    def perform_at(time, worker_params)
      delay = (time.utc - Time.now.utc).round
      if delay < 0
        delay = 0
      end
      self.perform_in(delay, worker_params)
    end

    def perform_in(delay, worker_params)
      job_id = SecureRandom.uuid
      payload = build_job_payload(worker_params, job_id, delay)
      client.send_message({
        # TODO : How to get this URL...
        queue_url: queue_url,
        message_body: payload.to_json
      })
    end

    def client
      @client ||= Aws::SQS::Client.new
    end

    def build_job_payload(worker_params, job_id, delay)
      {
        worker: self.name,
        worker_params: worker_params,
        jobId: job_id,
        delay: delay
      }
    end
  end
end
