require_relative '../config/boot'


# This class runs on a schedule (every minute, by default) and generates a series of jobs to be
# run over the next few minutes.
class RandomJobGenerator

  def self.call(event:, context:)
    job_count = 0
    jobs_to_generate = rand(ENV['MIN_RANDOM_JOBS_PER_MINUTE'].to_i..ENV['MAX_RANDOM_JOBS_PER_MINUTE'].to_i)
    sleep_delay = 53.0/jobs_to_generate # Calculate our sleep based on the target rates
    puts "jobs_to_generate = #{jobs_to_generate} and sleep_delay = #{sleep_delay}"
    while context.get_remaining_time_in_millis > 5_000 do # This lets us exit gracefully and resume on the next round instead of getting forcibly killed.
      delay = rand(0..ENV['MAX_JOB_DELAY_IN_SECONDS'].to_f) # Schedule the job for sometime between now and MAX_JOB_DELAY
      job_sleep = rand(0..ENV['MAX_JOB_LENGTH_IN_SECONDS'].to_f) # Then sleep for up to MAX_SLEEP_DELAY
      error_percentage = ENV['ERROR_PERCENTAGE'].to_i

      # Schedule a job to be performed after our randomly generated delay
      [HelloWorker, GreetingsWorker].sample.perform_in(delay, {
        mode: 'later',
        message: 'msg: from random job generator - ' + SecureRandom.hex,
        delay: delay,
        error_percentage: error_percentage,
        job_sleep: job_sleep
      })
      job_count += 1
      puts "message delay = #{delay} and sleep delay = #{sleep_delay} - job_count = #{job_count}"

      # Now sleep before generating the next job
      sleep(sleep_delay)
    end
  end

end

