module Funktor
  class Counter
    attr_accessor :dimension

    def initialize(dimension)
      @dimension = dimension
    end

    def incr(job)
      put_metric_to_stdout(job)
    end

    def put_metric_to_stdout(job)
      # NOTE : We use raw puts here instead of Funktor.logger.something to avoid getting extra
      # timestamps or log level information in the log line. We need this specific format to
      # be the only thing in the line so that CloudWatch can parse the logs and use the data.
      puts Funktor.dump_json(metric_hash(job))
    end

    def metric_hash(job)
      {
        "_aws": {
          "Timestamp": Time.now.strftime('%s%3N').to_i,
          "CloudWatchMetrics": [
            {
              "Namespace": ENV['FUNKTOR_APP_NAME'],
              "Dimensions": [["WorkerClassName"], ["Queue"]],
              "Metrics": [ # CPU, Memory, Duration, etc...
                           {
                             "Name": dimension,
                             "Unit": "Count"
                           }
              ]
            }
          ]
        },
        "WorkerClassName": job.worker_class_name,
        "Queue": job.queue,
        "#{dimension}": 1
        #"count": value,
        #"requestId": "989ffbf8-9ace-4817-a57c-e4dd734019ee"
      }
      #data[key] = value
    end
  end
end
