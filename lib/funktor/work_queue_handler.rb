require 'aws-sdk-sqs'

module Funktor
  class WorkQueueHandler
    include Funktor::ErrorHandler

    def initialize
      @failed_counter = Funktor::Counter.new('failed')
      @processed_counter = Funktor::Counter.new('processed')
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
      begin
        Funktor.work_queue_handler_middleware.invoke(job) do
          job.execute
        end
        @processed_counter.incr(job)
      # rescue Funktor::Job::InvalidJsonError # TODO Make this work
      rescue Exception => e
        handle_error(e, job)
        @failed_counter.incr(job)
        attempt_retry_or_bail(job)
      end
    end

    def attempt_retry_or_bail(job)
      if job.can_retry
        trigger_retry(job)
      else
        Funktor.logger.error "We retried max times. We're bailing on this one."
        Funktor.logger.error job.to_json
      end
    end

    def trigger_retry(job)
      job.increment_retries
      Funktor.logger.error "scheduling retry # #{job.retries} with delay of #{job.delay}"
      Funktor.logger.error job.to_json
      sqs_client.send_message({
        queue_url: job.retry_queue_url,
        message_body: job.to_json
      })
    end

  end
end