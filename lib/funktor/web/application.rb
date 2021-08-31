require 'sinatra/base'
require 'aws-sdk-dynamodb'
require_relative '../../funktor'
require_relative '../../funktor/shard_utils'
require_relative '../../funktor/activity_tracker'

module Funktor
  module Web
    class Application < Sinatra::Base
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

      get '/queued' do
        erb :queued, layout: :layout, locals: {
          activity_data: get_activity_data,
          jobs: get_jobs('queued')
        }
      end

      get '/processing' do
        erb :processing, layout: :layout, locals: {
          activity_data: get_activity_data,
          jobs: get_jobs('processing')
        }
      end

      post '/update_jobs' do
        job_ids = params[:job_id]
        if job_ids.is_a?(String)
          job_ids = [job_ids]
        end
        job_ids ||= []
        puts "params[:submit] = #{params[:submit]}"
        puts "job_ids = #{job_ids}"
        puts "params[:source] = #{params[:source]}"
        if params[:submit] == "Delete Selected Jobs"
          delete_jobs(job_ids, params[:source])
        elsif params[:submit] == "Queue Selected Jobs"
          queue_jobs(job_ids, params[:source])
        end
        redirect request.referrer
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
            ":jobShard" => "stat"
          },
          key_condition_expression: "jobShard = :jobShard",
          projection_expression: "jobId, stat_value",
          table_name: ENV['FUNKTOR_JOBS_TABLE']
        }
        resp = dynamodb_client.query(query_params)
        @activity_stats = {}
        resp.items.each do |item|
          @activity_stats[item["jobId"]] = item["stat_value"].to_i
        end
        return @activity_stats
      end

      def queue_jobs(job_ids, source)
        job_activator = Funktor::JobActivator.new
        job_ids.each do |job_id|
          job_shard = calculate_shard(job_id)
          job_activator.activate_job(job_shard, job_id, source, true)
        end
      end

      def delete_jobs(job_ids, source)
        @tracker = Funktor::ActivityTracker.new
        job_ids.each do |job_id|
          delete_single_job(job_id, source)
        end
      end

      def delete_single_job(job_id, source)
        response = dynamodb_client.delete_item({
          key: {
            "jobShard" => calculate_shard(job_id),
            "jobId" => job_id
          },
          table_name: ENV['FUNKTOR_JOBS_TABLE'],
          return_values: "ALL_OLD"
        })
        if response.attributes # this means the record was still there
          if source == "scheduled"
            @tracker.track(:scheduledJobDeleted, nil)
          elsif source == "retry"
            @tracker.track(:retryDeleted, nil)
          end
        end
      end

      def dynamodb_client
        @dynamodb_client ||= ::Aws::DynamoDB::Client.new
      end

      # start the server if ruby file executed directly
      run! if app_file == $0
    end
  end
end

