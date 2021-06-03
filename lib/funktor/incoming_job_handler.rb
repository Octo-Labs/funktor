require 'aws-sdk-sqs'

module Funktor
  class IncomingJobHandler

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
      Funktor.incoming_job_handler_middleware.invoke(job) do
        puts "pushing to active_job_queue for delay = #{job.delay}"
        push_to_active_job_queue(job)
      end
    end

    def active_job_queue
      ENV['FUNKTOR_ACTIVE_JOB_QUEUE']
    end

    def delayed_job_table
      ENV['FUNKTOR_DELAYED_JOB_TABLE']
    end

    def push_to_active_job_queue(job)
      sqs_client.send_message({
        # TODO : How to get this URL...
        queue_url: active_job_queue,
        message_body: job.to_json,
        delay_seconds: job.delay
      })
    end

  end
end
