class HelloWorker
  include Funktor::Worker

  def perform(*args)
    puts "Greetings from the HelloWorker!"
  end
end

