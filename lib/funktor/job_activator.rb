require 'aws-sdk-dynamodb'
require 'aws-sdk-sqs'

module Funktor
  class JobActivator

    def initialize
      @tracker = Funktor::ActivityTracker.new
    end

    def dynamodb_client
      @dynamodb_client ||= ::Aws::DynamoDB::Client.new
    end

    def sqs_client
      @sqs_client ||= ::Aws::SQS::Client.new
    end

    def delayed_job_table
      ENV['FUNKTOR_JOBS_TABLE']
    end

    def jobs_to_activate
      # TODO : The lookahead time here should be configurable
      # If this doesn't match the setting in the IncomingJobHandler some jobs
      # might be activated and then immediately re-scheduled instead of being
      # queued, which leads to kind of confusing stats for the "incoming" stat.
      # (Come to think of it, the incoming stat is kind of confusting anyway since
      # it reflects retries and scheduled jobs activations...)
      target_time = (Time.now + 60).utc
      query_params = {
        expression_attribute_values: {
          ":queueable" => "true",
          ":targetTime" => target_time.iso8601
        },
        key_condition_expression: "queueable = :queueable AND performAt < :targetTime",
        projection_expression: "jobId, jobShard, category",
        table_name: delayed_job_table,
        index_name: "performAtIndex"
      }
      resp = dynamodb_client.query(query_params)
      return resp.items
    end

    def queue_for_job(job)
      queue_name = job.queue || 'default'
      queue_constant = "FUNKTOR_#{queue_name.underscore.upcase}_QUEUE"
      Funktor.logger.debug "queue_constant = #{queue_constant}"
      Funktor.logger.debug "ENV value = #{ENV[queue_constant]}"
      ENV[queue_constant] || ENV['FUNKTOR_DEFAULT_QUEUE']
    end

    def handle_item(item)
      job_shard = item["jobShard"]
      job_id = item["jobId"]
      current_category = item["category"]
      Funktor.logger.debug "jobShard = #{item['jobShard']}"
      Funktor.logger.debug "jobId = #{item['jobId']}"
      Funktor.logger.debug "current_category = #{current_category}"
      activate_job(job_shard, job_id, current_category)
    end

    def activate_job(job_shard, job_id, current_category, queue_immediately = false)
      
      # TODO: WorkQueueVisibilityMiddleware to alter what happens here? Maybe we delete by default and then the middleware puts it back in the table?
      # First we conditionally update the item in  Dynamo to be sure that another scheduler hasn't gotten
      # to it, and if that works then send to SQS. This is basically how Sidekiq scheduler works.
      response = if Funktor.enable_work_queue_visibility
                   dynamodb_client.update_item({
                     key: {
                       "jobShard" => job_shard,
                       "jobId" => job_id
                     },
                     update_expression: "SET category = :category, queueable = :queueable",
                     condition_expression: "category = :current_category",
                     expression_attribute_values: {
                       ":current_category" => current_category,
                       ":queueable" => "false",
                       ":category" => "queued"
                     },
                     table_name: delayed_job_table,
                     return_values: "ALL_OLD"
                   })
                 else
                   dynamodb_client.delete_item({
                     key: {
                       "jobShard" => job_shard,
                       "jobId" => job_id
                     },
                     condition_expression: "category = :current_category",
                     expression_attribute_values: {
                       ":current_category" => current_category
                     },
                     table_name: delayed_job_table,
                     return_values: "ALL_OLD"
                   })
                 end
      if response.attributes # this means the record was still there in the state we expected
        Funktor.logger.debug "response.attributes ====== "
        Funktor.logger.debug response.attributes
        job = Funktor::Job.new(response.attributes["payload"])
        Funktor.logger.debug "we created a job from payload"
        Funktor.logger.debug response.attributes["payload"]
        Funktor.logger.debug "queueing to #{job.retry_queue_url}"
        if queue_immediately
          job.delay = 0
        end
        sqs_client.send_message({
          queue_url: job.retry_queue_url,
          message_body: job.to_json
          #delay_seconds: job.delay
        })
        if job.is_retry?
          # We don't track here because we send stuff back to the incoming job queue and we track the
          # :retryActivated even there.
          # TODO - Once we're sure this is all working right we can delete the commented out line.
          #@tracker.track(:retryActivated, job)
        else
          @tracker.track(:scheduledJobActivated, job)
        end
      end
    rescue ::Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
      # This means that a different instance of the JobActivator (or someone doing stuff in the web UI)
      # got to the job first.
      Funktor.logger.debug "#{e.to_s} : #{e.message}"
      Funktor.logger.debug e.backtrace.join("\n")
    end

    def call(event:, context:)
      handled_item_count = 0
      jobs_to_activate.each do |item|
        if context.get_remaining_time_in_millis < 5_000 # This lets us exit gracefully and resume on the next round instead of getting forcibly killed.
          puts "Bailing out due to milliseconds remaining #{context.get_remaining_time_in_millis}"
          break
        end
        handle_item(item)
        handled_item_count += 1
      end
    end
  end
end
