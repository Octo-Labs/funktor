# frozen_string_literal: true
module Funktor
  class Rails < ::Rails::Engine
    # This hook happens after `Rails::Application` is inherited within
    # config/application.rb and before config is touched, usually within the
    # class block. Definitely before config/environments/*.rb and
    # config/initializers/*.rb.
    config.before_configuration do
      if defined?(::ActiveJob)
        require "sidekiq/worker"
        require 'active_job/queue_adapters/funktor_adapter'
      end
    end

    initializer "funktor.active_job_integration" do
      ActiveSupport.on_load(:active_job) do
        include ::Sidekiq::Worker unless respond_to?(:sidekiq_options)
      end
    end
  end if defined?(::Rails)

  if defined?(::Rails) && ::Rails::VERSION::MAJOR < 5
    raise "🚫 ERROR: Funktor does not support Rails versions under 5.x"
  end
end
