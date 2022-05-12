require_relative '../spec_support/job_spec_helpers'
require 'active_support/core_ext/hash/keys'

RSpec.describe Funktor::JobActivator, type: :handler do
  include JobSpecHelpers

  let(:dynamodb_client){ double Aws::DynamoDB::Client }
  let(:sqs_client){ double Aws::SQS::Client }
  let(:event){ {} }
  let(:lambda_context){ double "Context", get_remaining_time_in_millis: 10_000 }

  let(:job_id){ SecureRandom.uuid }
  let(:shard){ job_id.hash % 64 }
  let(:query_response) do
    double items: [{
      "performAt": Time.now.utc.iso8601,
      "jobShard": shard,
      "jobId": job_id,
      "payload": Funktor.dump_json({})
    }.stringify_keys],
    attributes: {}
  end
  let(:update_response) do
    double items: [],
      attributes: {
        "performAt": Time.now.utc.iso8601,
        "jobShard": shard,
        "jobId": job_id,
        "payload": Funktor.dump_json({})
      }.stringify_keys
  end

  let(:delayed_job_activator) do
    Funktor::JobActivator.new()
  end

  before do
    allow(Funktor).to receive(:sqs_client).and_return(sqs_client)
    allow(Funktor).to receive(:dynamodb_client).and_return(dynamodb_client)

    # TODO - Clean this up and really test something...
    fake_tracker = double(Funktor::ActivityTracker, track: nil)
    allow(Funktor::ActivityTracker).to receive(:new).and_return(fake_tracker)
  end

  describe 'call when work queue visibility is enabled' do
    before do
      Funktor.enable_work_queue_visibility = true
    end
    it 'should send a message to the ActiveJobQueue and update the item' do
      expect(dynamodb_client).to receive(:query).and_return(query_response)
      expect(dynamodb_client).to receive(:update_item).and_return(update_response)
      expect(sqs_client).to receive(:send_message).and_return(nil)
      delayed_job_activator.call(event: event, context: lambda_context)
    end
  end

  describe 'call when work queue visibility is disabled' do
    before do
      Funktor.enable_work_queue_visibility = false
    end
    it 'should send a message to the ActiveJobQueue and delete the item' do
      expect(dynamodb_client).to receive(:query).and_return(query_response)
      expect(dynamodb_client).to receive(:delete_item).and_return(update_response)
      expect(sqs_client).to receive(:send_message).and_return(nil)
      delayed_job_activator.call(event: event, context: lambda_context)
    end
  end

end

