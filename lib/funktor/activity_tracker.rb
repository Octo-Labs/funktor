require 'json'

module Funktor
  class ActivityTracker

    INCR_KEYS = {
      incoming: 'incoming',
      queued: 'queued',
      scheduled: 'scheduled',
      processingStarted: 'processing',
      processingComplete: 'complete',
      processingFailed: 'failed',
      bailingOut: 'failed',
      retrying: 'retries',
      retryActivated: 'queued',
      scheduledJobActivated: nil,
      scheduledJobDeleted: 'scheduledJobDeleted',
      retryDeleted: 'retryDeleted'
      #scheduledJobPushedToActive: 'active',
      #activeJobPushed: 'active',
      #scheduledJobPushed: 'scheduled'
    }

    DECR_KEYS = {
      incoming: nil,
      queued: nil,
      scheduled: nil,
      processingStarted: 'queued',
      processingComplete: 'processing',
      processingFailed: nil,
      bailingOut: 'processing',
      retrying: 'processing',
      retryActivated: 'retries',
      scheduledJobActivated: 'scheduled',
      scheduledJobDeleted: 'scheduled',
      retryDeleted: 'retries'
      #scheduledJobPushedToActive: 'scheduled',
      #activeJobPushed: nil,
      #scheduledJobPushed: nil
    }

    def track(activity, job)
      unless Funktor.enable_activity_tracking
        Funktor.logger.debug "activity tracking is disabled"
        return
      end
      Funktor.logger.debug "starting track activity for #{activity}"
      incrKey = nil || INCR_KEYS[activity.to_sym]
      decrKey = nil || DECR_KEYS[activity.to_sym]
      if incrKey
        increment_key(incrKey)
      end
      if decrKey
        decrement_key(decrKey)
      end
      Funktor.logger.debug "ending track activity for #{activity}"
    end

    def increment_key(key)
      #put_metric_to_stdout(key, 1)
      dynamodb_client.update_item({
        table_name: ENV['FUNKTOR_JOBS_TABLE'],
        key: { jobShard: 'stat', jobId: key },
        expression_attribute_values:{ ":start": 0, ":inc": 1 },
        update_expression: "SET stat_value = if_not_exists(stat_value, :start) + :inc",
      })
    end

    def decrement_key(key)
      #put_metric_to_stdout(key, -1)
      dynamodb_client.update_item({
        table_name: ENV['FUNKTOR_JOBS_TABLE'],
        key: { jobShard: 'stat', jobId: key },
        expression_attribute_values:{ ":start": 0, ":inc": 1 },
        update_expression: "SET stat_value = if_not_exists(stat_value, :start) - :inc",
      })
    end

    def dynamodb_client
      Funktor.dynamodb_client
    end

    def metric_namespace
      [ENV['FUNKTOR_APP_NAME'], ENV['SERVERLESS_STAGE']].join('-')
    end

    def put_metric_to_stdout(key, value)
      data = {
        "_aws": {
          "Timestamp": Time.now.strftime('%s%3N').to_i,
          "CloudWatchMetrics": [
            {
              "Namespace": metric_namespace,
              "Dimensions": [["functionVersion"]],
              "Metrics": [ # CPU, Memory, Duration, etc...
                           {
                             "Name": key,
                             "Unit": "Count"
                           }
              ]
            }
          ]
        },
        "functionVersion": "LATEST",
        #"count": value,
        #"requestId": "989ffbf8-9ace-4817-a57c-e4dd734019ee"
      }
      data[key] = value
      puts(data.to_json)
    end

  end
end
