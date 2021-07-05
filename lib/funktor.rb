require "funktor/version"
require 'funktor/aws/sqs/event'
require 'funktor/aws/sqs/record'
require 'funktor/counter'
require 'funktor/job'
require 'funktor/logger'
require 'funktor/worker'
require 'funktor/middleware_chain'
require 'funktor/incoming_job_handler'

require 'json'

module Funktor
  class Error < StandardError; end

  DEFAULT_OPTIONS = {
    error_handlers: [],
    log_level: Logger::DEBUG # Set a high log level during early, active development
  }

  def self.configure_job_pusher
    yield self
  end

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

  # TODO - Maybe we don't need this either? Maybe this should be a super dumb thing that also
  # just pushed JSON around? Maybe we want to centralize middlewares in only two spots?
  # 1. Job pushing.
  # 2. Job execution.
  # 🤔
  def self.configure_incoming_job_handler
    yield self
  end

  def self.incoming_job_handler_middleware
    @incoming_job_handler_chain ||= MiddlewareChain.new
    yield @incoming_job_handler_chain if block_given?
    @incoming_job_handler_chain
  end

  def self.parse_json(string)
    JSON.parse(string)
  end

  def self.dump_json(object)
    JSON.generate(object)
  end

  def self.options
    @options ||= DEFAULT_OPTIONS.dup
  end

  def self.options=(opts)
    @options = opts
  end

  # Register a proc to handle any error which occurs within the Funktor active job handler.
  #
  #   Funktor.error_handlers << proc {|error, context| ErrorsAsAService.notify(error, context) }
  #
  # The default error handler logs errors to STDOUT
  def self.error_handlers
    options[:error_handlers]
  end

  def self.logger
    @logger ||= Funktor::Logger.new($stdout, level: options[:log_level])
  end

  def self.logger=(logger)
    if logger.nil?
      self.logger.level = Logger::FATAL
      return self.logger
    end

    @logger = logger
  end
end

# TODO - Should we require this by default or let people opt in?
# TODO - Is it a code smell that we need to include these at the bottom, after
# the main Funktor module is defined?
require 'funktor/middleware/metrics'
require 'funktor/error_handler'
require 'funktor/active_job_handler'
