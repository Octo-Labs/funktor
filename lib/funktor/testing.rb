module Funktor
  class Testing

    def self.inline!(&block)
      Funktor.configure_job_pusher do |config|
        config.job_pusher_middleware do |chain|
          chain.add Funktor::InlineJobPusherMiddleware
        end
      end
      yield
      Funktor.configure_job_pusher do |config|
        config.job_pusher_middleware do |chain|
          chain.remove Funktor::InlineJobPusherMiddleware
        end
      end
    end

  end

  class InlineJobPusherMiddleware
    def call(worker, payload)
      worker.new.perform(payload[:worker_params])
    end
  end
end
