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
    records = event["Records"]
    puts "Records.size = #{records.count}"
    records.each do |record|
      dispatch(record)
    end
  end

  def self.sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def self.dispatch(record)
    job_body = record["body"]
    puts "dispatching job : #{job_body}"
    payload = JSON.parse(job_body)
    klass_name = payload["worker"]
    params = payload["worker_params"]
    begin
      klass = find_job_klass(klass_name)
      klass.new.perform(params)
    rescue Exception => e
      puts "Error during processing: #{$!}"
      puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      attempt_retry_or_bail(payload)
    end
  end

  def self.attempt_retry_or_bail(payload)
    if payload["retries"] && payload["retries"] > 25
      puts "We retried 25 times. We're bailing on this one."
      puts payload
    else
      trigger_retry(payload)
    end
  end

  def self.trigger_retry(payload)
    payload["retries"] ||= 0
    payload["retries"] += 1
    payload["delay"] = seconds_to_delay(payload["retries"])
    puts "scheduling retry # #{payload["retries"]} with delay of #{payload["delay"]}"
    puts payload
    sqs_client.send_message({
      # TODO : How to get this URL...
      queue_url: SQS_URL,
      message_body: payload.to_json
    })
  end

  def self.find_job_klass(klass_name)
    klass = Object.const_get klass_name
    return klass
  end

  def self.underscore(word)
    word = word.dup
    word.gsub!(/::/, '/')
    word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end

  # delayed_job and sidekiq use the same basic formula
  def self.seconds_to_delay(count)
    (count**4) + 15 + (rand(30) * (count + 1))
  end
end
