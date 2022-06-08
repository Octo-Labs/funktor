require 'new_relic/agent'
# This is kind of a brute force approach that's not very performant. It's based on this documentaion:
# https://docs.newrelic.com/docs/apm/agents/ruby-agent/background-jobs/monitor-ruby-background-processes
#
# It might be better if we could use the NewRelic Lambda Layer, but currently it doesn't seem to support Ruby.
# https://docs.newrelic.com/docs/serverless-function-monitoring/aws-lambda-monitoring/get-started/monitoring-aws-lambda-serverless-monitoring
module Funktor
  module Middleware
    class NewRelic
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def call(job)
        ::NewRelic::Agent.manual_start(:sync_startup => true)
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
        ::NewRelic::Agent.shutdown
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




