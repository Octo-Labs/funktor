require 'yaml'
require 'active_support/core_ext/string/inflections'

module Funktor
  module CLI
    class Init < Thor::Group
      include Thor::Actions

      attr_accessor :work_queue_name
      attr_accessor :work_queue_config

      class_option :deployment_framework, :aliases => "-d",
        :type => :string, :desc => "The deployment/provisioning framework to use.",
        :default => "serverless"

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The funktor init file.",
        :default => "funktor_init.yml"

      desc <<~DESC
        Description:
          Initialize a new funktor deployment directory.
      DESC

      def self.source_root
        File.join File.dirname(__FILE__), 'templates'
      end

      def self.destination_root
        name
      end

      def funktor_config_yml
        #template "funktor_config.yml", File.join("funktor_config.yml")
        template File.join("funktor_config", "funktor.yml"), File.join("funktor_config", "funktor.yml")
        template File.join("funktor_config", "ruby_layer.yml"), File.join("funktor_config", "ruby_layer.yml")
        template File.join("funktor_config", "package.yml"), File.join("funktor_config", "package.yml")
        template File.join("funktor_config", "environment.yml"), File.join("funktor_config", "environment.yml")
        template File.join("funktor_config", "boot.rb"), File.join("funktor_config", "boot.rb")
      end

      def package_json
        if File.exist?("package.json")
          package_data = File.open("package.json").read
          if package_data =~ /serverless-ruby-layer/
            say "serverless-ruby-layer is already installed in package.json"
          else
            if File.exist?("package-lock.json")
              run "npm install serverless-ruby-layer@1.4.0"
              # TODO - Add handers for yarn and what not
            else
              say "You should install serverless-ruby-layer version 1.4.0 using yor package manager of choice."
            end
          end
        else
          template "package.json", File.join("package.json")
        end
      end

      def gemfile
        if File.exist?("Gemfile")
          gem_data = File.open("Gemfile").read
          if gem_data =~ /funktor/
            say "funktor is already installed in Gemfile"
          else
            run "bundle add funktor"
          end
        else
          template "Gemfile", File.join("Gemfile")
        end
      end

      def gitignore
        template "gitignore", File.join(".gitignore")
      end

      def workers
        template File.join("app", "workers", "hello_worker.rb"), File.join("app", "workers", "hello_worker.rb")
      end

      def resources
        template File.join("funktor_config", "resources", "incoming_job_queue.yml"), File.join("funktor_config", "resources", "incoming_job_queue.yml")
        template File.join("funktor_config", "resources", "incoming_job_queue_user.yml"), File.join("funktor_config", "resources", "incoming_job_queue_user.yml")
        # TODO - Figure out how to make the dashboard aware of various queues...
        template File.join("funktor_config", "resources", "cloudwatch_dashboard.yml"), File.join("funktor_config", "resources", "cloudwatch_dashboard.yml")
        queues.each do |queue_details|
          @work_queue_name = queue_details.keys.first
          @work_queue_config = queue_details.values.first
          template File.join("funktor_config", "resources", "work_queue.yml"), File.join("funktor_config", "resources", "#{work_queue_name.underscore}_queue.yml")
        end
        template File.join("funktor_config", "resources", "jobs_table.yml"), File.join("funktor_config", "resources", "jobs_table.yml")
      end

      def iam_permissions
        template File.join("funktor_config", "iam_permissions", "ssm.yml"), File.join("funktor_config", "iam_permissions", "ssm.yml")
        template File.join("funktor_config", "iam_permissions", "incoming_job_queue.yml"), File.join("funktor_config", "iam_permissions", "incoming_job_queue.yml")
        queues.each do |queue_details|
          @work_queue_name = queue_details.keys.first
          @work_queue_config = queue_details.values.first
          template File.join("funktor_config", "iam_permissions", "work_queue.yml"), File.join("funktor_config", "iam_permissions", "#{work_queue_name.underscore}_queue.yml")
        end
        template File.join("funktor_config", "iam_permissions", "jobs_table.yml"), File.join("funktor_config", "iam_permissions", "jobs_table.yml")
        template File.join("funktor_config", "iam_permissions", "jobs_table_secondary_index.yml"), File.join("funktor_config", "iam_permissions", "jobs_table_secondary_index.yml")
      end

      def function_definitions
        template File.join("funktor_config", "function_definitions", "incoming_job_handler.yml"), File.join("funktor_config", "function_definitions", "incoming_job_handler.yml")
        template File.join("funktor_config", "function_definitions", "job_activator.yml"), File.join("funktor_config", "function_definitions", "job_activator.yml")
        queues.each do |queue_details|
          @work_queue_name = queue_details.keys.first
          @work_queue_config = queue_details.values.first
          template File.join("funktor_config", "function_definitions", "work_queue_handler.yml"), File.join("funktor_config", "function_definitions", "#{work_queue_name.underscore}_queue_handler.yml")
        end
      end

      def lambda_handlers
        template File.join("lambda_event_handlers", "incoming_job_handler.rb"), File.join("lambda_event_handlers", "incoming_job_handler.rb")
        template File.join("lambda_event_handlers", "job_activator.rb"), File.join("lambda_event_handlers", "job_activator.rb")
        queues.each do |queue_details|
          @work_queue_name = queue_details.keys.first
          @work_queue_config = queue_details.values.first
          template File.join("lambda_event_handlers", "work_queue_handler.rb"), File.join("lambda_event_handlers", "#{work_queue_name.underscore}_queue_handler.rb")
        end
      end

      def serverless_yml
        template "serverless.yml", File.join("serverless.yml")
      end

      private

      def app_worker_names
        app_worker_files.map do |file|
          File.basename(file, ".rb").camelize
        end
      end

      def app_worker_files
        Dir.glob(File.join('app', 'workers', '**.rb'))
      end

      def all_iam_permissions
        Dir.glob(File.join('funktor_config', 'iam_permissions', '**.yml'))
      end

      def all_function_definitions
        Dir.glob(File.join('funktor_config', 'function_definitions', '**.yml'))
      end

      def all_resources
        Dir.glob(File.join('funktor_config', 'resources', '**.yml'))
      end

      def funktor_config
        @funktor_config ||= YAML.load_file options[:file]
      end

      def name
        funktor_config["appName"]
      end

      def app_name
        funktor_config["appName"]
      end

      def runtime
        funktor_config["runtime"]
      end

      def queues
        funktor_config["queues"]
      end

      def queue_names
        funktor_config["queues"].map{|queue_details| queue_details.keys.first }
      end

      def work_queue_name
        @work_queue_name
      end

      def work_queue_config
        @work_queue_config
      end

      def queue_config(queue_name)
        funktor_config["queues"].each do |queue_details|
          if queue_details.keys.first == queue_name
            return queue_details.values.first
          end
        end
        return nil
      end

      def incoming_config_value(config_name)
        funktor_config.dig("incomingJobHandler", config_name) ||
          funktor_config.dig("handlerDefaults", config_name) ||
          "null" # When we parse yaml 'null' gets turned to nil, which comes out as an empty string in the template
      end

      def activator_config_value(config_name)
        funktor_config.dig("jobActivator", config_name) ||
          funktor_config.dig("handlerDefaults", config_name) ||
          "null" # When we parse yaml 'null' gets turned to nil, which comes out as an empty string in the template
      end

      def queue_config_value(queue_name, config_name)
        queue_config(queue_name)&.dig(config_name) ||
          funktor_config.dig("handlerDefaults", config_name) ||
          "null" # When we parse yaml 'null' gets turned to nil, which comes out as an empty string in the template

      end

    end
  end
end
