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
    def call(worker, payload)
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

  #it 'uses funktor_options to select the right queue' do
    #TestJobWithOptions.perform_later(42)
    #expect(ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.size).to eq(1)
    #job = ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.first
    #expect(job[:payload][:queue]).to eq("custom")
  #end
end

    #it 'can pass along options' do
      ## funktor_options is not thread-safe; this is not a recommended pattern to use
      ## in production, set options in the ActiveJob class definition only
      #TestJob.funktor_options({})
      #TestJob.perform_later(123)

      #TestJob.funktor_options(retry: 9)
      #TestJob.perform_later(123)

      #TestJob.funktor_options(retry: 9, unique_for: 10)
      #TestJob.perform_later(123)

      #job = ActiveJob::QueueAdapters::FunktorAdapter::JobWrapper.jobs.last
      #assert_equal 9, job["retry"]
      #assert_equal 10, job["custom"]["unique_for"]
      #assert_equal "FunktorAdapterTest::TestJob", job["custom"]["wrapped"]
    #end

    
