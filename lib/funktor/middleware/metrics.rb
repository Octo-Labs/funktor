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
        puts Funktor.dump_json(metric_hash(time_diff, job))
      end

      def metric_hash(time_diff_in_seconds, job)
        {
          "_aws": {
            "Timestamp": Time.now.strftime('%s%3N').to_i,
            "CloudWatchMetrics": [
              {
                "Namespace": ENV['FUNKTOR_APP_NAME'],
                "Dimensions": [["WorkerClassName", "Queue"]],
                "Metrics": [ # CPU, Memory, Duration, etc...
                             {
                               "Name": "Duration",
                               "Unit": "Milliseconds"
                             }
                ]
              }
            ]
          },
          "WorkerClassName": job.worker_class_name,
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

Funktor.configure_active_job_handler do |config|
  config.active_job_handler_middleware do |chain|
    chain.add Funktor::Middleware::Metrics
  end
end


