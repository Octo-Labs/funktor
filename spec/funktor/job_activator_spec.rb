require_relative '../spec_support/job_spec_helpers'
require 'active_support/core_ext/hash/keys'

RSpec.describe Funktor::JobActivator, type: :handler do
  include JobSpecHelpers

  let(:dynamodb_client){ double Aws::DynamoDB::Client }
  let(:sqs_client){ double Aws::SQS::Client }
  let(:event){ {} }
  let(:lambda_context){ double "Context", get_remaining_time_in_millis: 10_000 }
  let(:delayed_job_activator) do
    Funktor::JobActivator.new()
  end

  before do
    expect(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
    expect(Aws::DynamoDB::Client).to receive(:new).and_return(dynamodb_client)
  end

  describe 'call' do
    context 'in the middle of the day with one job ready' do
      let(:response) do
        double items: [{
          "performAt": Time.now.utc.iso8601,
          "performAtDate": Time.now.utc.to_date.iso8601,
          "jobId": SecureRandom.uuid,
          "payload": Funktor.dump_json({})
        }.stringify_keys],
        attributes: {}
      end
      before do
        expect(dynamodb_client).to receive(:query).and_return(response)
        expect(dynamodb_client).to receive(:delete_item).and_return(response)
      end
      it 'should send a message to the ActiveJobQueue then delete the item' do
        expect(sqs_client).to receive(:send_message).and_return(nil)
        delayed_job_activator.call(event: event, context: lambda_context)
      end
    end
    context 'near midnight' do
      skip 'TBD'
    end
  end
end

