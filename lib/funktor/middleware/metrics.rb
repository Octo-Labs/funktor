module Funktor
  module Middleware
    class Metrics
      def call(job)
        start_time = Time.now.utc
        yield
        end_time = Time.now.utc
        time_diff = end_time - start_time
        put_metric_to_stdout(time_diff, job)
      end

      def put_metric_to_stdout(time_diff, job)
        # NOTE : We use raw_logger here instead of Funktor.loggert o avoid getting extra
        # timestamps or log level information in the log line. We need this specific format to
        # be the only thing in the line so that CloudWatch can parse the logs and use the data.
        # 'unknown' is a log level that will always be logged, no matter what is set in the
        # runtime environment as far as log level.
        Funktor.raw_logger.unknown Funktor.dump_json(metric_hash(time_diff, job))
      end

      def metric_namespace
        [ENV['FUNKTOR_APP_NAME'], ENV['SERVERLESS_STAGE']].join('-')
      end

      def metric_hash(time_diff_in_seconds, job)
        {
          "_aws": {
            "Timestamp": Time.now.strftime('%s%3N').to_i,
            "CloudWatchMetrics": [
              {
                "Namespace": metric_namespace,
                "Dimensions": [["WorkerClassName"], ["Queue"]],
                "Metrics": [ # CPU, Memory, Duration, etc...
                             {
                               "Name": "Duration",
                               "Unit": "Milliseconds"
                             }
                ]
              }
            ]
          },
          "WorkerClassName": job.worker_class_name_for_metrics,
          "Queue": job.queue,
          "Duration": time_diff_in_seconds * 1_000
          #"count": value,
          #"requestId": "989ffbf8-9ace-4817-a57c-e4dd734019ee"
        }
        #data[key] = value
      end

    end
  end
end

Funktor.configure_work_queue_handler do |config|
  config.work_queue_handler_middleware do |chain|
    chain.add Funktor::Middleware::Metrics
  end
end


