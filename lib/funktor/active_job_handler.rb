require 'json'
require 'aws-sdk-sqs'
#require_relative './activity_helper'

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'
Bundler.require

# This class is connected to the ActiveJobQueue in SQS.
# The event contains a Records array with each record representing one job.
class Funktor::ActiveJobHandler
  SQS_URL = "https://sqs.us-east-1.amazonaws.com/925259170958/ruby-lambda-experiment-dev-incoming-jobs"

  def self.call(event:, context:)
    event = Funktor::Aws::Sqs::Event.new(event)
    puts "event.jobs.count = #{event.jobs.count}"
    event.jobs.each do |job|
      dispatch(job)
    end
  end

  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def self.dispatch(job)
    begin
      job.execute
    rescue Exception => e
      puts "Error during processing: #{$!}"
      puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      attempt_retry_or_bail(job)
    end
  end

  def self.attempt_retry_or_bail(job)
    if job.can_retry
      trigger_retry(job)
    else
      puts "We retried max times. We're bailing on this one."
      puts job.to_json
    end
  end

  def self.trigger_retry(job)
    job.increment_retries
    puts "scheduling retry # #{job.retries} with delay of #{job.delay}"
    puts job.to_json
    sqs_client.send_message({
      # TODO : How to get this URL...
      queue_url: SQS_URL,
      message_body: job.to_json
    })
  end
end
