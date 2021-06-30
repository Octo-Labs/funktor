require 'aws-sdk-sqs'

module Funktor
  class ActiveJobHandler

    def initialize
      @failed_counter = Funktor::Counter.new('failed')
      @processed_counter = Funktor::Counter.new('processed')
    end

    def call(event:, context:)
      event = Funktor::Aws::Sqs::Event.new(event)
      puts "event.jobs.count = #{event.jobs.count}"
      event.jobs.each do |job|
        dispatch(job)
      end
    end

    def sqs_client
      @sqs_client ||= ::Aws::SQS::Client.new
    end

    def dispatch(job)
      begin
        Funktor.active_job_handler_middleware.invoke(job) do
          job.execute
        end
        @processed_counter.incr(job)
      # rescue Funktor::Job::InvalidJsonError # TODO Make this work
      rescue Exception => e
        puts "Error during processing: #{$!}"
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
        @failed_counter.incr(job)
        attempt_retry_or_bail(job)
      end
    end

    def attempt_retry_or_bail(job)
      if job.can_retry
        trigger_retry(job)
      else
        puts "We retried max times. We're bailing on this one."
        puts job.to_json
      end
    end

    def trigger_retry(job)
      job.increment_retries
      puts "scheduling retry # #{job.retries} with delay of #{job.delay}"
      puts job.to_json
      sqs_client.send_message({
        queue_url: job.retry_queue_url,
        message_body: job.to_json
      })
    end

  end
end
