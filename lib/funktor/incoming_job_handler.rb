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
      Funktor.sqs_client
    end

    def dynamodb_client
      Funktor.dynamodb_client
    end

    def dispatch(job)
      Funktor.incoming_job_handler_middleware.invoke(job) do
        # TODO : This number should be configurable via ENV var
        if job.delay < 60 # for now we're testing with just one minute * 5 # 5 minutes
          Funktor.logger.debug "pushing to work queue for delay = #{job.delay}"
          if Funktor.enable_work_queue_visibility
            # We push to the jobs table first becauase the work queue handler will expect to be able
            # to update the stats of a record that's already in the table.
            # TODO : For time sensitive jobs this is probably less than optimal. Can we update the
            # work queue handler to be ok with a job that's not yet in the table?
            push_to_jobs_table(job, "queued")
          end
          push_to_work_queue(job)
          if job.is_retry?
            @tracker.track(:retryActivated, job)
          else
            @tracker.track(:queued, job)
          end
        else
          Funktor.logger.debug "pushing to jobs table for delay = #{job.delay}"
          push_to_jobs_table(job, nil)
          if job.is_retry?
            # do nothing for tracking
          else
            @tracker.track(:scheduled, job)
          end
        end
        @tracker.track(:incoming, job)
      end
    end

    def push_to_work_queue(job)
      Funktor.logger.debug "job = #{job.to_json}"
      sqs_client.send_message({
        queue_url: job.work_queue_url,
        message_body: job.to_json,
        delay_seconds: job.delay
      })
    end

    def delayed_job_table
      ENV['FUNKTOR_JOBS_TABLE']
    end

    def push_to_jobs_table(job, category = nil)
      resp = dynamodb_client.put_item({
        item: {
          payload: job.to_json,
          jobId: job.job_id,
          performAt: job.perform_at.iso8601,
          jobShard: job.shard,
          queueable: category.present? ? "false" : "true",
          category: category || (job.is_retry? ? "retry" : "scheduled")
        },
        table_name: delayed_job_table
      })
    end

  end
end
