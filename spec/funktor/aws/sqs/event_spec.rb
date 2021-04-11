require_relative '../../../spec_support/job_spec_helpers'

RSpec.describe Funktor::Aws::Sqs::Event do
  include JobSpecHelpers
  let(:event_data){ create_event }
  let(:event){ Funktor::Aws::Sqs::Event.new(event_data) }
  it 'has an array of recors' do
    expect(event.records.length).to eq(2)
    expect(event.records.first).to be_instance_of(Funktor::Aws::Sqs::Record)
  end
end
