require "active_support/core_ext/hash/indifferent_access"

module Funktor
  module FakeJobQueue
    def self.push(payload)
      payload = payload.with_indifferent_access
      jobs[payload["worker"].to_s].push({payload: payload})
    end

    def self.jobs
      @jobs ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def self.clear_all
      jobs.clear
    end
  end
end
