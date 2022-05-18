class JobFlood
  attr_accessor :length_in_minutes
  attr_accessor :min_jobs_per_minute
  attr_accessor :max_jobs_per_minute
  attr_accessor :max_job_length_in_seconds
  attr_accessor :error_percentage
  attr_accessor :error_percentage

  def initialize length_in_minutes: 5, min_jobs_per_minute: 30, max_jobs_per_minute: 120, max_job_length_in_seconds: 3, error_percentage: 25
    @length_in_minutes = length_in_minutes
    @min_jobs_per_minute = min_jobs_per_minute
    @max_jobs_per_minute = max_jobs_per_minute
    @max_job_length_in_seconds = max_job_length_in_seconds
    @error_percentage = error_percentage
  end

  def flood
    total_jobs = 0
    length_in_minutes.times do |minute|
      jobs_to_generate = rand(min_jobs_per_minute..max_jobs_per_minute)
      jobs_to_generate.times do
        total_jobs += 1
        job_target_time = Time.now + (minute * 60) + rand(60)
        job_sleep = rand(0.0..max_job_length_in_seconds.to_f)
        puts job_target_time
        [AuditWorker, AuditWorker, SingleThreadAuditWorker, HelloWorker, GreetingsWorker].sample.perform_at(job_target_time, {
          mode: 'later',
          message: 'msg: from random JobFlood - ' + SecureRandom.hex,
          target_time: job_target_time,
          error_percentage: error_percentage,
          job_sleep: job_sleep
        })
      end
    end
    puts "generated #{total_jobs} jobs over the next #{length_in_minutes} minutes"
  end

end
