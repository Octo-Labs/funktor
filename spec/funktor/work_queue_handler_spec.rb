require 'funktor/work_queue_handler'
require 'funktor/worker'

require_relative '../spec_support/job_spec_helpers'

RSpec.describe Funktor::WorkQueueHandler, type: :handler do
  include JobSpecHelpers

  let(:sqs_client){ double Aws::SQS::Client }
  let(:single_job_event){ create_event [HelloWorker] }
  let(:double_job_event){ create_event [HelloWorker, HelloWorker] }
  let(:fail_once_job_event){ create_event [FailWorker] }
  let(:no_retry_job_event){ create_event [NoRetryWorker] }
  let(:custom_retry_job_event){ create_event [CustomRetryWorker] }
  let(:dynamodb_client){ double Aws::DynamoDB::Client }
  let(:work_queue_handler){ Funktor::WorkQueueHandler.new }

  before :each do
    # TODO - Clean this up and really test something...
    fake_tracker = double(Funktor::ActivityTracker, track: nil)
    allow(Funktor::ActivityTracker).to receive(:new).and_return(fake_tracker)
  end

  describe 'call with work queue visibility enabled' do
    before do
      Funktor.enable_work_queue_visibility = true
    end
    it "calls perform on a worker" do
      expect(dynamodb_client).to receive(:update_item).and_return(nil)
      expect(dynamodb_client).to receive(:delete_item).and_return(nil)
      expect(work_queue_handler).to receive(:dynamodb_client).twice.and_return(dynamodb_client)
      expect_any_instance_of(HelloWorker).to receive(:perform).and_call_original
      work_queue_handler.call(event: single_job_event, context: {})
    end
    it "calls dispatch twice for two jobs" do
      expect_any_instance_of(Funktor::WorkQueueHandler).to receive(:dispatch).twice.and_return(nil)
      work_queue_handler.call(
        event: double_job_event,
        context: {}
      )
    end
    context 'on failure' do
      before do
        allow(Funktor).to receive(:sqs_client).and_return(sqs_client)
      end
      it "sends a message to the IncomingJobQueue to retry on failure" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        expect(dynamodb_client).to receive(:update_item).twice.and_return(nil)
        expect(work_queue_handler).to receive(:dynamodb_client).twice.and_return(dynamodb_client)
        work_queue_handler.call(
          event: fail_once_job_event,
          context: {}
        )
      end
      it "sends a message to the IncomingJobQueue with a custom retry time" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        expect(dynamodb_client).to receive(:update_item).twice.and_return(nil)
        expect(work_queue_handler).to receive(:dynamodb_client).twice.and_return(dynamodb_client)
        work_queue_handler.call(
          event: custom_retry_job_event,
          context: {}
        )
      end
      it "does not send a message to the IncomingJobQueue if the worker can't retry" do
        expect(sqs_client).not_to receive(:send_message)
        expect(dynamodb_client).to receive(:update_item).twice.and_return(nil)
        expect(work_queue_handler).to receive(:dynamodb_client).twice.and_return(dynamodb_client)
        work_queue_handler.call(
          event: no_retry_job_event,
          context: {}
        )
      end
    end
  end

  describe 'call with work queue visibility disabled' do
    before do
      Funktor.enable_work_queue_visibility = false
    end
    it "calls perform on a worker" do
      expect_any_instance_of(HelloWorker).to receive(:perform).and_call_original
      work_queue_handler.call(event: single_job_event, context: {})
    end
    it "calls dispatch twice for two jobs" do
      expect_any_instance_of(Funktor::WorkQueueHandler).to receive(:dispatch).twice.and_return(nil)
      work_queue_handler.call(
        event: double_job_event,
        context: {}
      )
    end
    context 'on failure' do
      before do
        allow(Funktor).to receive(:sqs_client).and_return(sqs_client)
      end
      it "sends a message to the IncomingJobQueue to retry on failure" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        work_queue_handler.call(
          event: fail_once_job_event,
          context: {}
        )
      end
      it "sends a message to the IncomingJobQueue to retry on failure" do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        work_queue_handler.call(
          event: custom_retry_job_event,
          context: {}
        )
      end
      it "does not sends message to the IncomingJobQueue if the job can't retry" do
        expect(sqs_client).not_to receive(:send_message)
        work_queue_handler.call(
          event: no_retry_job_event,
          context: {}
        )
      end
    end
  end
end
