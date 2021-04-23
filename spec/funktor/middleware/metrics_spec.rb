require 'funktor/job'

RSpec.describe Funktor::Middleware::Metrics do
  let(:job_double){ double Funktor::Job, worker_class_name: "MiddlewareTestWorker" }
  describe 'call' do
    it 'yields to a block and writes to standard out' do
      block_was_called = false
      expect{
        Funktor::Middleware::Metrics.new.call(job_double) do
          block_was_called = true
        end
      }.to output.to_stdout
      expect(block_was_called).to be_truthy
    end
  end

  describe 'metric_hash' do
    # TODO - Figure out how deep we should go on testing this and then flesh it out.
    it 'produces a properly formatted hash' do
      hash = Funktor::Middleware::Metrics.new.metric_hash(1,job_double)
      expect(hash[:_aws]).to be_present
    end
  end
end
