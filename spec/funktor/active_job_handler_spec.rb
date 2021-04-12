require 'funktor/active_job_handler'
require 'funktor/worker'

require_relative '../spec_support/job_spec_helpers'

RSpec.describe Funktor::ActiveJobHandler, type: :handler do
  include JobSpecHelpers

  let(:sqs_client){ double Aws::SQS::Client }
  let(:single_job_event){ create_event [HelloWorker] }
  let(:double_job_event){ create_event [HelloWorker, HelloWorker] }
  let(:fail_once_job_event){ create_event [FailWorker] }

  describe 'call' do
    it "calls perform on a worker" do
      expect_any_instance_of(HelloWorker).to receive(:perform).and_return(nil)
      Funktor::ActiveJobHandler.call(
        event: single_job_event,
        context: {}
      )
    end
    it "calls dispatch twice for two jobs" do
      expect(Funktor::ActiveJobHandler).to receive(:dispatch).twice.and_return(nil)
      Funktor::ActiveJobHandler.call(
        event: double_job_event,
        context: {}
      )
    end
    context 'on failure' do
      before do
        expect(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      end
      it "sends a message to the ActiveJobQueue to retry on failure" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        Funktor::ActiveJobHandler.call(
          event: fail_once_job_event,
          context: {}
        )
      end
    end
  end
end
