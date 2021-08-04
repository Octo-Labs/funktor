require "funktor/version"
require 'funktor/aws/sqs/event'
require 'funktor/aws/sqs/record'
require 'funktor/counter'
require 'funktor/job'
require 'funktor/job_pusher'
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

  def self.job_pusher
    @job_pusher ||= JobPusher.new
  end

  def self.job_pusher_middleware
    @job_pusher_chain ||= MiddlewareChain.new
    yield @job_pusher_chain if block_given?
    @job_pusher_chain
  end

  def self.configure_work_queue_handler
    yield self
  end

  def self.work_queue_handler_middleware
    @work_queue_handler_chain ||= MiddlewareChain.new
    yield @work_queue_handler_chain if block_given?
    @work_queue_handler_chain
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

  # We have a raw_logger that doesn't add timestamps and what not. This is used to publish
  # CloudWatch metrics that can be used in dashboards.
  def self.raw_logger
    @raw_logger ||= Funktor::Logger.new($stdout, level: options[:log_level], formatter: proc {|severity, datetime, progname, msg|
      "#{msg}\n"
    })
  end

  def self.raw_logger=(raw_logger)
    if raw_logger.nil?
      self.raw_logger.level = Logger::FATAL
      return self.raw_logger
    end

    @raw_logger = raw_logger
  end
end

# TODO - Is it a code smell that we need to include these at the bottom, after
# the main Funktor module is defined?
#
# TODO - Should we require metrics by default or let people opt in?
require 'funktor/middleware/metrics'
require 'funktor/error_handler'
require 'funktor/work_queue_handler'

require 'funktor/rails' if defined?(::Rails::Engine)
