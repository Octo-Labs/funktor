require 'aws-sdk-sqs'
require 'active_support/core_ext/string/inflections'

module Funktor
  class IncomingJobHandler

    def initialize
      @tracker = Funktor::ActivityTracker.new
    end

    def call(event:, context:)
      event = Funktor::Aws::Sqs::Event.new(event)
      Funktor.logger.debug "event.jobs.count = #{event.jobs.count}"
      event.jobs.each do |job|
        dispatch(job)
      end
    end

    def sqs_client
      @sqs_client ||= ::Aws::SQS::Client.new
    end

    def dispatch(job)
      Funktor.incoming_job_handler_middleware.invoke(job) do
        Funktor.logger.debug "pushing to work queue for delay = #{job.delay}"
        push_to_work_queue(job)
        @tracker.track(:queued, job)
      end
    end

    def queue_for_job(job)
      queue_name = job.queue || 'default'
      queue_constant = "FUNKTOR_#{queue_name.underscore.upcase}_QUEUE"
      Funktor.logger.debug "queue_constant = #{queue_constant}"
      Funktor.logger.debug "ENV value = #{ENV[queue_constant]}"
      ENV[queue_constant] || ENV['FUNKTOR_DEFAULT_QUEUE']
    end

    def push_to_work_queue(job)
      Funktor.logger.debug "job = #{job.to_json}"
      sqs_client.send_message({
        queue_url: queue_for_job(job),
        message_body: job.to_json,
        delay_seconds: job.delay
      })
    end

  end
end
