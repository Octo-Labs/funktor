module Funktor
  module CLI
    class Init < Thor::Group

      class_option :framework, :aliases => "-f",
        :type => :string, :desc => "The deployment/provisioning framework to use.",
        :default => "serverless"
      class_option :directory, :aliases => "-d",
        :type => :string, :desc => "The directory to initialize",
        :default => "funktor"

      desc <<~DESC
        Description:
          Initialize a new funktor deployment directory.
      DESC

      def serverless_yml
        puts "#{options[:directory]}/serverless.yml"
      end

      def package_json
        puts "#{options[:directory]}/package.json"
      end

      def gemfile
        puts "#{options[:directory]}/Gemfile"
      end

      def resources
        puts "#{options[:directory]}/resources/incoming-job-queue.yml"
        puts "#{options[:directory]}/resources/incoming-job-queue-user.yml"
        puts "#{options[:directory]}/resources/active-job-queue.yml"
        puts "#{options[:directory]}/resources/cloudwatch-dashboard.yml"
      end

      def lambda_handlers
        puts "#{options[:directory]}/handlers/incoming_job_handler.rb"
        puts "#{options[:directory]}/handlers/active_job_handler.rb"
      end

      def workers
        puts "#{options[:directory]}/workers/hello_worker.rb"
      end
    end
  end
end
