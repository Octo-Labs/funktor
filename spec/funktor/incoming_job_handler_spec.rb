
require_relative '../spec_support/job_spec_helpers'

RSpec.describe Funktor::IncomingJobHandler, type: :handler do
  include JobSpecHelpers

  let(:delay){ 0 }
  let(:single_job_event){ create_event [HelloWorker], delay }
  let(:sqs_client){ double Aws::SQS::Client }
  let(:dynamodb_client){ double Aws::DynamoDB::Client }
  let(:incoming_job_handler) do
    Funktor::IncomingJobHandler.new()
  end

  before :each do
    # TODO - Clean this up and really test something...
    fake_tracker = double(Funktor::ActivityTracker, track: nil)
    allow(Funktor::ActivityTracker).to receive(:new).and_return(fake_tracker)
  end

  describe 'call' do
    describe 'with a short delay' do
      it 'should send a message to the work queue' do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        expect(incoming_job_handler).to receive(:sqs_client).and_return(sqs_client)
        incoming_job_handler.call(event: single_job_event, context: {})
      end
    end
    describe 'with a long delay' do
      let(:delay){ 1800 }
      it 'should save a record to DynamoDB' do
        expect(dynamodb_client).to receive(:put_item).and_return(nil)
        expect(incoming_job_handler).to receive(:dynamodb_client).and_return(dynamodb_client)
        incoming_job_handler.call(event: single_job_event, context: {})
      end
    end
  end
end


