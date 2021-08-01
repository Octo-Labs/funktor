require 'active_job/queue_adapters/funktor_adapter'

# TODO
# quiet a lot of AJ noise
ActiveJob::Base.logger = Logger.new(nil)

RSpec.describe ActiveJob::QueueAdapters::FunktorAdapter, type: :adapter do
  class TestJob < ActiveJob::Base
    self.queue_adapter = :funktor
    cattr_accessor :count
    @@count = 0
    def perform(*args)
      args.each do |value|
        self.class.count += value
      end
    end
  end

  class TestJobWithOptions < ActiveJob::Base
    self.queue_adapter = :funktor
    funktor_options queue: :custom
    def perform(*args)
    end
  end

  class ActiveJobTestMiddleware
    cattr_accessor :middleware_count
    @@middleware_count = 0
    def call(payload)
      self.class.middleware_count += 1
      yield
    end
  end

  around do |example|
    require 'funktor/testing'
    Funktor::Testing.fake! do
      example.run
    end
    ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.clear
    TestJob.count = 0
  end

  it 'queues a job in the JobWrapper queue' do
    expect(ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.size).to eq(0)
    TestJob.perform_later(42)
    expect(ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.size).to eq(1)
  end

  it 'can perform a job' do
    TestJob.perform_later(42)
    ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.work_all_jobs
    expect(TestJob.count).to eq(42)
  end

  it 'can perform a job with multiple arguments' do
    TestJob.perform_later(1,2,3)
    ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.work_all_jobs
    expect(TestJob.count).to eq(6)
  end

  it 'executes job_pusher_middlewares on push' do
    Funktor.job_pusher_middleware do |chain|
      chain.prepend ActiveJobTestMiddleware
    end
    expect(ActiveJobTestMiddleware.middleware_count).to eq(0)
    TestJob.perform_later(123)
    expect(ActiveJobTestMiddleware.middleware_count).to eq(1)
    Funktor.job_pusher_middleware.remove(ActiveJobTestMiddleware)
  end

  it 'uses funktor_options to select the right queue' do
    TestJobWithOptions.perform_later(42)
    expect(ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.size).to eq(1)
    job = ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.first
    puts "job ==========="
    pp job
    expect(job[:payload]["queue"]).to eq("custom")
  end
end

