require 'json'
RSpec.describe Funktor::Job do
  let(:event_data){ JSON.parse(File.open('spec/fixtures/sqs_active_job_queue_event.json').read) }
  let(:event){ Funktor::Aws::Sqs::Event.new(event_data) }
  let(:job){ event.jobs.first }
  it 'can be accessed from a well formed event' do
    expect(job).to be_instance_of(Funktor::Job)
  end
end
