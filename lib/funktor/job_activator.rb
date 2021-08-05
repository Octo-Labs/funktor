require 'aws-sdk-dynamodb'
require 'aws-sdk-sqs'

module Funktor
  class JobActivator

    def dynamodb_client
      @dynamodb_client ||= ::Aws::DynamoDB::Client.new
    end

    def sqs_client
      @sqs_client ||= ::Aws::SQS::Client.new
    end

    def active_job_queue
      ENV['FUNKTOR_ACTIVE_JOB_QUEUE']
    end

    def delayed_job_table
      ENV['FUNKTOR_JOBS_TABLE']
    end

    def jobs_to_activate
      target_time = (Time.now + 90).utc
      query_params = {
        expression_attribute_values: {
          ":targetDate" => target_time.to_date.iso8601,
          ":targetTime" => target_time.iso8601
        },
        key_condition_expression: "performAtDate = :targetDate AND performAt < :targetTime",
        projection_expression: "payload, performAt, jobId, performAtDate",
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
      job = Funktor::Job.new(item["payload"])
      Funktor.logger.debug "we created a job from payload"
      Funktor.logger.debug item["payload"]
      delay = (Time.parse(item["performAt"]) - Time.now.utc).to_i
      if delay < 0
        delay = 0
      end
      # First we delete the item from Dynamo to be sure that another scheduler hasn't gotten to it,
      # and if that works then send to SQS. This is basically how Sidekiq scheduler works.
      response = dynamodb_client.delete_item({
        key: {
          "performAtDate" => item["performAtDate"],
          "jobId" => item["jobId"]
        },
        table_name: delayed_job_table,
        return_values: "ALL_OLD"
      })
      if response.attributes # this means the record was still there
        sqs_client.send_message({
          # TODO : How to get this URL...
          queue_url: queue_for_job(job),
          message_body: item["payload"],
          delay_seconds: delay
        })
      end
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
