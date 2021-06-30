require_relative '../spec_support/job_spec_helpers'
RSpec.describe Funktor::Job do
  include JobSpecHelpers
  let(:event_data){ create_event }
  let(:event){ Funktor::Aws::Sqs::Event.new(event_data) }
  let(:job){ event.jobs.first }
  it 'can be accessed from a well formed event' do
    expect(job).to be_instance_of(Funktor::Job)
  end

  it 'returns a worker class name' do
    expect(job.worker_class_name).to eq("HelloWorker")
  end

  it 'can execut the job' do
    expect_any_instance_of(HelloWorker).to receive(:perform).with(1, 'two')
    job.execute
  end
end
