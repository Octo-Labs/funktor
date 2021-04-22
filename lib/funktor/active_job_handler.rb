require 'json'
require 'aws-sdk-sqs'
require_relative './job'
require_relative './aws/sqs/event'
#require_relative './activity_helper'

module Funktor
  class ActiveJobHandler

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
        job.execute
      rescue Exception => e
        puts "Error during processing: #{$!}"
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
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
        message_body: job.to_json,
        delay_seconds: job.delay
      })
    end

  end
end
