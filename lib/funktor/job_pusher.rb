require 'aws-sdk-sqs'

module Funktor
  class JobPusher

    # TODO : Refactor this so that it doesn't rely on an instantiated worker class.
    # We should be able to push jobs without real workers being involved on the pushing side.
    def push(worker, payload)
      job_id = SecureRandom.uuid
      payload[:job_id] = job_id

      Funktor.job_pusher_middleware.invoke(worker, payload) do
        client.send_message({
          queue_url: queue_url(worker),
          message_body: Funktor.dump_json(payload)
        })
      end
    end

    private

    def client
      @client ||= ::Aws::SQS::Client.new
    end

    def queue_url(worker)
      worker.queue_url || ENV['FUNKTOR_INCOMING_JOB_QUEUE']
    end
  end
end
