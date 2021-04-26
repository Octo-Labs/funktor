require 'funktor/testing'

RSpec.describe Funktor::Testing do
  around do |example|
    $worker_history = []
    Funktor::Testing.inline! do
      example.run
    end
  end

  class InlineWorker
    include Funktor::Worker
    def perform(*args)
      $worker_history.push self.class.name
    end
  end

  it 'runs the worker inline' do
    expect($worker_history.count).to eq(0)
    InlineWorker.perform_async
    expect($worker_history.count).to eq(1)
    expect($worker_history).to eq(["InlineWorker"])
  end
end
