class AuditWorker
  include Funktor::Worker

  def perform(arg_hash)
    time_now = Time.now
    target_time = Time.parse arg_hash['target_time']
    time_diff = time_now - target_time
    Funktor.raw_logger.unknown Funktor.dump_json(metric_hash(time_diff))

    puts "Greetings from the #{self.class.name}! Time diff = #{time_diff}"
    puts arg_hash.class.name
    puts arg_hash

    if arg_hash["error_percentage"] && rand(100) < arg_hash["error_percentage"].to_i
      raise "Oops, we encountered a 'random error'"
    end
    if arg_hash["job_sleep"]
      puts "Working (sleeping) for #{arg_hash["job_sleep"]} seconds"
      sleep arg_hash["job_sleep"]
    end
    puts "So long from the #{self.class.name}, and thanks for all the fish!"
  end

  def metric_hash(time_diff)
    {
      "_aws": {
        "Timestamp": Time.now.strftime('%s%3N').to_i,
        "CloudWatchMetrics": [
          {
            "Namespace": ENV['FUNKTOR_APP_NAME'],
            "Dimensions": [["WorkerClassName"]],
            "Metrics": [ # CPU, Memory, Duration, etc...
                         {
                           "Name": "TimeDiff",
                           "Unit": "Seconds"
                         }
            ]
          }
        ]
      },
      "WorkerClassName": self.class.name,
      "TimeDiff": time_diff
      #"count": value,
      #"requestId": "989ffbf8-9ace-4817-a57c-e4dd734019ee"
    }
    #data[key] = value
  end
end

