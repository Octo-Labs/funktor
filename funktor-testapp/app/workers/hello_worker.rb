class HelloWorker
  include Funktor::Worker

  def perform(*args)
    Funktor.logger.debug "Greetings from the HelloWorker!"
  end
end

