class HelloWorker
  include Funktor::Worker

  def perform(arg_hash)
    puts "Greetings from the #{self.class.name}!"
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
end

