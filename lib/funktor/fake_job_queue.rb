module Funktor
  module FakeJobQueue
    def self.push(worker, payload)
      jobs[worker.name].push({worker: worker, payload: payload})
    end

    def self.jobs
      @jobs ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def self.clear_all
      jobs.clear
    end
  end
end
