require 'aws-sdk-sqs'
require 'active_support/core_ext/string/inflections'

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

    def queue_for_job(job)
      queue_name = job.queue || 'default'
      queue_constant = "FUNKTOR_#{queue_name.underscore.upcase}_QUEUE"
      ENV[queue_constant] || ENV['FUNKTOR_DEFAULT_QUEUE']
    end

    def push_to_active_job_queue(job)
      puts "job = #{job.to_json}"
      sqs_client.send_message({
        # TODO : How to get this URL...
        queue_url: queue_for_job(job),
        message_body: job.to_json,
        delay_seconds: job.delay
      })
    end

  end
end
