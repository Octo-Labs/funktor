require 'sinatra'
require 'aws-sdk-dynamodb'
require_relative '../../funktor'

get '/' do
  erb :index, layout: :layout, locals: {
    activity_data: get_activity_data
  }
end

get '/scheduled' do
  erb :scheduled, layout: :layout, locals: {
    activity_data: get_activity_data,
    jobs: get_jobs('scheduled')
  }
end

get '/retries' do
  erb :retries, layout: :layout, locals: {
    activity_data: get_activity_data,
    jobs: get_jobs('retry')
  }
end

def get_jobs(category)
  "Jobs of type #{category}"
  query_params = {
    expression_attribute_values: {
      ":category" => category
    },
    key_condition_expression: "category = :category",
    projection_expression: "payload, performAt, jobId, jobShard",
    table_name: ENV['FUNKTOR_JOBS_TABLE'],
    index_name: "categoryIndex"
  }
  resp = dynamodb_client.query(query_params)
  @items = resp.items
  @jobs = @items.map{ |item| Funktor::Job.new(item["payload"]) }
  return @jobs
end

def get_activity_data
  query_params = {
    expression_attribute_values: {
      ":category" => "stat"
    },
    key_condition_expression: "category = :category",
    projection_expression: "statName, stat_value",
    table_name: ENV['FUNKTOR_ACTIVITY_TABLE']
  }
  resp = dynamodb_client.query(query_params)
  @activity_stats = {}
  resp.items.each do |item|
    @activity_stats[item["statName"]] = item["stat_value"].to_i
  end
  return @activity_stats
end

def dynamodb_client
  @dynamodb_client ||= ::Aws::DynamoDB::Client.new
end
