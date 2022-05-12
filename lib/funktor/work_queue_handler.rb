require 'aws-sdk-sqs'
require 'aws-sdk-dynamodb'

module Funktor
  class WorkQueueHandler
    include Funktor::ErrorHandler

    def initialize
      @failed_counter = Funktor::Counter.new('failed')
      @processed_counter = Funktor::Counter.new('processed')
      @tracker = Funktor::ActivityTracker.new
    end

    def call(event:, context:)
      event = Funktor::Aws::Sqs::Event.new(event)
      Funktor.logger.debug "event.jobs.count = #{event.jobs.count}"
      event.jobs.each do |job|
        dispatch(job)
      end
    end

    def dynamodb_client
      @dynamodb_client ||= ::Aws::DynamoDB::Client.new
    end

    def sqs_client
      @sqs_client ||= ::Aws::SQS::Client.new
    end

    def dispatch(job)
      begin
        @tracker.track(:processingStarted, job)
        if Funktor.enable_work_queue_visibility
          update_job_category(job, "processing")
        end
        Funktor.work_queue_handler_middleware.invoke(job) do
          job.execute
        end
        @processed_counter.incr(job)
        @tracker.track(:processingComplete, job)

        if Funktor.enable_work_queue_visibility
          delete_job_from_dynamodb(job)
        end
      # rescue Funktor::Job::InvalidJsonError # TODO Make this work
      rescue Exception => e
        handle_error(e, job)
        @failed_counter.incr(job)
        job.error = e
        if job.can_retry
          @tracker.track(:retrying, job)

          if Funktor.enable_work_queue_visibility
            update_job_category(job, "retry")
          end
          trigger_retry(job)
        else
          @tracker.track(:bailingOut, job)

          if Funktor.enable_work_queue_visibility
            update_job_category(job, "dead")
          end
          Funktor.logger.error "We retried max times. We're bailing on this one."
          Funktor.logger.error job.to_json
        end
        @tracker.track(:processingFailed, job)
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

    def delayed_job_table
      ENV['FUNKTOR_JOBS_TABLE']
    end

    def update_job_category(job, category)
      dynamodb_client.update_item({
        key: {
          "jobShard" => job.shard,
          "jobId" => job.job_id
        },
        table_name: delayed_job_table,
        update_expression: "SET category = :category, queueable = :queueable",
        expression_attribute_values: {
          ":queueable" => "false",
          ":category" => category
        },
        return_values: "ALL_OLD"
      })
    end

    def delete_job_from_dynamodb(job)
      dynamodb_client.delete_item({
        key: {
          "jobShard" => job.shard,
          "jobId" => job.job_id
        },
        table_name: delayed_job_table,
        return_values: "ALL_OLD"
      })
    end

  end
end
