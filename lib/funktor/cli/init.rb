require 'yaml'

module Funktor
  module CLI
    class Init < Thor::Group
      include Thor::Actions

      class_option :deployment_framework, :aliases => "-d",
        :type => :string, :desc => "The deployment/provisioning framework to use.",
        :default => "serverless"

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The funktor init file.",
        :default => "funktor.yml"

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

      def serverless_yml
        template "serverless.yml", File.join("serverless.yml")
      end

      def funktor_config_yml
        #template "funktor_config.yml", File.join("funktor_config.yml")
        template File.join("config", "funktor.yml"), File.join("config", "funktor.yml")
        template File.join("config", "ruby_layer.yml"), File.join("config", "ruby_layer.yml")
        template File.join("config", "package.yml"), File.join("config", "package.yml")
        template File.join("config", "environment.yml"), File.join("config", "environment.yml")
      end

      def package_json
        template "package.json", File.join("package.json")
      end

      def gemfile
        template "Gemfile", File.join("Gemfile")
      end

      def gitignore
        template "gitignore", File.join(".gitignore")
      end

      def resources
        template File.join("config", "resources", "incoming_job_queue.yml"), File.join("config", "resources", "incoming_job_queue.yml")
        template File.join("config", "resources", "incoming_job_queue_user.yml"), File.join("config", "resources", "incoming_job_queue_user.yml")
        template File.join("config", "resources", "active_job_queue.yml"), File.join("config", "resources", "active_job_queue.yml")
        # TODO - Figure out how to make the dashboard aware of various queues...
        template File.join("config", "resources", "cloudwatch_dashboard.yml"), File.join("config", "resources", "cloudwatch_dashboard.yml")
        # TODO Finish this...
        queues.each do |queue|

        end
      end

      def iam_permissions
        template File.join("config", "iam_permissions", "ssm.yml"), File.join("config", "iam_permissions", "ssm.yml")
        template File.join("config", "iam_permissions", "incoming_job_queue.yml"), File.join("config", "iam_permissions", "incoming_job_queue.yml")
        template File.join("config", "iam_permissions", "active_job_queue.yml"), File.join("config", "iam_permissions", "active_job_queue.yml")
        # TODO Finish this...
        queues.each do |queue|

        end
      end

      def function_definitions
        template File.join("config", "function_definitions", "active_job_handler.yml"), File.join("config", "function_definitions", "active_job_handler.yml")
        template File.join("config", "function_definitions", "incoming_job_handler.yml"), File.join("config", "function_definitions", "incoming_job_handler.yml")
        # TODO Finish this...
        queues.each do |queue|

        end
      end

      def lambda_handlers
        template File.join("app", "handlers", "active_job_handler.rb"), File.join("app", "handlers", "active_job_handler.rb")
        template File.join("app", "handlers", "incoming_job_handler.rb"), File.join("app", "handlers", "incoming_job_handler.rb")
        # TODO Finish this...
        queues.each do |queue|

        end
      end

      def workers
        template File.join("app", "workers", "hello_worker.rb"), File.join("app", "workers", "hello_worker.rb")
      end

      private
      def funktor_config
        @funktor_config ||= YAML.load_file options[:file]
      end

      def name
        funktor_config["appName"]
      end

      def runtime
        funktor_config["runtime"]
      end

      def queues
        funktor_config["queues"]
      end
      end
    end
  end
end
