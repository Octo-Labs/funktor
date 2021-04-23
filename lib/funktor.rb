require "funktor/version"
require 'funktor/aws/sqs/event'
require 'funktor/aws/sqs/record'
require 'funktor/job'
require 'funktor/worker'
require 'funktor/middleware_chain'
require 'funktor/active_job_handler'

require 'json'

module Funktor
  class Error < StandardError; end
  # Your code goes here...

  def self.job_pusher_middleware
    @job_pusher_chain ||= MiddlewareChain.new
    yield @job_pusher_chain if block_given?
    @job_pusher_chain
  end

  def self.configure_active_job_handler
    yield self
  end

  def self.active_job_handler_middleware
    @active_job_handler_chain ||= MiddlewareChain.new
    yield @active_job_handler_chain if block_given?
    @active_job_handler_chain
  end

  def self.parse_json(string)
    JSON.parse(string)
  end

  def self.dump_json(object)
    JSON.generate(object)
  end
end

# TODO - Should we require this by default or let people opt in?
# Is it a code smell that we need to include it at the bottom, after
# the main Funktor module is defined?
require 'funktor/middleware/metrics'
