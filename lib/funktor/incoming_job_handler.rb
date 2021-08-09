require 'aws-sdk-sqs'
require 'aws-sdk-dynamodb'
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

    def dynamodb_client
      @dynamodb_client ||= ::Aws::DynamoDB::Client.new
    end

    def dispatch(job)
      Funktor.incoming_job_handler_middleware.invoke(job) do
        # TODO : This number should be configurable via ENV var
        if job.delay < 60 # for now we're testing with just one minute * 5 # 5 minutes
          Funktor.logger.debug "pushing to work queue for delay = #{job.delay}"
          push_to_work_queue(job)
          if job.is_retry?
            @tracker.track(:retryActivated, job)
          else
            @tracker.track(:queued, job)
          end
        else
          Funktor.logger.debug "pushing to jobs table for delay = #{job.delay}"
          push_to_jobs_table(job)
          if job.is_retry?
            # do nothing for tracking
          else
            @tracker.track(:scheduled, job)
          end
        end
        @tracker.track(:incoming, job)
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

    def delayed_job_table
      ENV['FUNKTOR_JOBS_TABLE']
    end

    def push_to_jobs_table(job)
      perform_at = (Time.now + job.delay).utc
      resp = dynamodb_client.put_item({
        item: {
          payload: job.to_json,
          jobId: job.job_id,
          performAt: perform_at.iso8601,
          performAtDate: perform_at.to_date.iso8601
        },
        table_name: delayed_job_table
      })
    end

  end
end
