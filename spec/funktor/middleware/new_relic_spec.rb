require 'funktor/job'
require 'funktor/middleware/new_relic'

RSpec.describe Funktor::Middleware::NewRelic do
  let(:job_double)do
    double Funktor::Job, worker_class_name_for_metrics: "MiddlewareTestWorker", queue: "default", worker_params: ['hi']
  end
  describe 'call' do
    it 'yields to a block traces via NewRelic' do
      block_was_called = false
      Funktor::Middleware::NewRelic.new.call(job_double) do
        block_was_called = true
      end
      expect(block_was_called).to be_truthy
    end
  end
end
