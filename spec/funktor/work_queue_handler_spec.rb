require 'funktor/work_queue_handler'
require 'funktor/worker'

require_relative '../spec_support/job_spec_helpers'

RSpec.describe Funktor::WorkQueueHandler, type: :handler do
  include JobSpecHelpers

  let(:sqs_client){ double Aws::SQS::Client }
  let(:single_job_event){ create_event [HelloWorker] }
  let(:double_job_event){ create_event [HelloWorker, HelloWorker] }
  let(:fail_once_job_event){ create_event [FailWorker] }

  before :each do
    # TODO - Clean this up and really test something...
    fake_tracker = double(Funktor::ActivityTracker, track: nil)
    allow(Funktor::ActivityTracker).to receive(:new).and_return(fake_tracker)
  end

  describe 'call' do
    it "calls perform on a worker" do
      expect_any_instance_of(HelloWorker).to receive(:perform).and_call_original
      Funktor::WorkQueueHandler.new.call(event: single_job_event, context: {})
    end
    it "calls dispatch twice for two jobs" do
      expect_any_instance_of(Funktor::WorkQueueHandler).to receive(:dispatch).twice.and_return(nil)
      Funktor::WorkQueueHandler.new.call(
        event: double_job_event,
        context: {}
      )
    end
    context 'on failure' do
      before do
        expect(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      end
      it "sends a message to the IncomingJobQueue to retry on failure" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        Funktor::WorkQueueHandler.new.call(
          event: fail_once_job_event,
          context: {}
        )
      end
    end
  end
end
