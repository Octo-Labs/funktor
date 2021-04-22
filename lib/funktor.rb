require "funktor/version"
require 'funktor/aws/sqs/event'
require 'funktor/aws/sqs/record'
require 'funktor/job'
require 'funktor/worker'
require 'funktor/middleware_chain'

module Funktor
  class Error < StandardError; end
  # Your code goes here...

  def self.job_pusher_middleware
    @job_pusher_chain ||= MiddlewareChain.new
    yield @job_pusher_chain if block_given?
    @job_pusher_chain
  end

  def self.active_job_handler_middleware
    @active_job_handler_chain ||= MiddlewareChain.new
    yield @active_job_handler_chain if block_given?
    @active_job_handler_chain
  end
end
