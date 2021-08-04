require 'aws-sdk-sqs'

module Funktor
  class JobPusher

    def push(payload)
      job_id = SecureRandom.uuid
      payload[:job_id] = job_id

      Funktor.job_pusher_middleware.invoke(payload) do
        client.send_message({
          queue_url: queue_url(payload),
          message_body: Funktor.dump_json(payload)
        })
        return job_id
      end
    end

    private

    def client
      @client ||= ::Aws::SQS::Client.new
    end

    def queue_url(payload)
      payload[:incoming_job_queue_url] || ENV['FUNKTOR_INCOMING_JOB_QUEUE']
    end
  end
end
