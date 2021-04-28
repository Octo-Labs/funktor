require 'funktor/testing'

RSpec.describe Funktor::Testing do
  around do |example|
    $worker_history = []
    Funktor::Testing.fake! do
      example.run
    end
    Funktor::Worker.clear_all
  end

  class FakeWorker
    include Funktor::Worker
    def perform(*args)
      $worker_history.push self.class.name
    end
  end

  it 'does not push to SQS or run the job inline' do
    expect($worker_history.count).to eq(0)
    FakeWorker.perform_async
    expect($worker_history.count).to eq(0)
    expect(FakeWorker.jobs.count).to eq(1)
  end

  it 'can work a job after storing it' do
    FakeWorker.perform_async
    expect(FakeWorker.jobs.count).to eq(1)
    FakeWorker.work_all_jobs
    expect(FakeWorker.jobs.count).to eq(0)
    expect($worker_history.count).to eq(1)
    expect($worker_history).to eq(['FakeWorker'])
  end
end
