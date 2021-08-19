require 'sinatra'
require 'aws-sdk-dynamodb'
require_relative '../../funktor'
require_relative '../../funktor/shard_utils'

include ShardUtils

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

post '/update_jobs' do
 job_ids = params[:job_id]
 if job_ids.is_a?(String)
   job_ids = [job_ids]
 end
 puts "params[:submit] = #{params[:submit]}"
 puts "job_ids = #{job_ids}"
 if params[:submit] == "Delete Selected Jobs"
   delete_jobs(job_ids)
   redirect request.referrer
 end
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

def delete_jobs(job_ids)
  job_ids.each_slice(25) do |slice|
    request_items = []
    slice.each do |job_id|
      request_items.push({
        delete_request: {
          key: {
            "jobShard" => calculate_shard(job_id),
            "jobId" => job_id
          }
        }
      })
    end
    pp request_items
    resp = dynamodb_client.batch_write_item({
      request_items: {
        "#{ENV['FUNKTOR_JOBS_TABLE']}": request_items
      }
    })
    pp resp
  end

end

def dynamodb_client
  @dynamodb_client ||= ::Aws::DynamoDB::Client.new
end
