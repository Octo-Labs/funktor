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

      def metric_hash(time_diff, job)
        {
          "_aws": {
            "Timestamp": Time.now.strftime('%s%3N').to_i,
            "CloudWatchMetrics": [
              {
                "Namespace": "rails-lambda-experiment", # TODO - We should get this from config or someting
                "Dimensions": [["WorkerClassName"]],
                "Metrics": [ # CPU, Memory, Duration, etc...
                             {
                               "Name": "Duration",
                               "Unit": "Seconds"
                             }
                ]
              }
            ]
          },
          "WorkerClassName": job.worker_class_name,
          "Seconds": time_diff
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


