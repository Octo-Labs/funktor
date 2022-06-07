require 'newrelic_rpm'
module Funktor
  module Middleware
    class NewRelic
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def call(job)
        trace_args = {
          :name => 'perform',
          :class_name => job.worker_class_name_for_metrics,
          :category => 'OtherTransaction/Funktor'
        }
        perform_action_with_newrelic_trace(trace_args) do
          ::NewRelic::Agent::Transaction.merge_untrusted_agent_attributes(job.worker_params,
                                                                        :'worker.funktor.params',
                                                                        ::NewRelic::Agent::AttributeFilter::DST_NONE)
          yield
        end
      end
    end
  end

  def self.new_relic!
    Funktor.configure_work_queue_handler do |config|
      config.work_queue_handler_middleware do |chain|
        chain.add Funktor::Middleware::NewRelic
      end
    end
  end
end




