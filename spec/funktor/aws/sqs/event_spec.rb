require 'json'
RSpec.describe Funktor::Aws::Sqs::Event do
  let(:event_data){ JSON.parse(File.open('spec/fixtures/sqs_active_job_queue_event.json').read) }
  let(:event){ Funktor::Aws::Sqs::Event.new(event_data) }
  it 'has an array of recors' do
    expect(event.records.length).to eq(2)
    expect(event.records.first).to be_instance_of(Funktor::Aws::Sqs::Record)
  end
end
