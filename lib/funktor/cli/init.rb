module Funktor
  module CLI
    class Init < Thor::Group
      include Thor::Actions

      argument :name, :type => :string, :desc => "The name of the app to initialize"

      class_option :framework, :aliases => "-f",
        :type => :string, :desc => "The deployment/provisioning framework to use.",
        :default => "serverless"

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
        template "serverless.yml", File.join(name, "serverless.yml")
      end

      def funktor_config_yml
        #template "funktor_config.yml", File.join(name, "funktor_config.yml")
        template File.join("config", "funktor.yml"), File.join(name, "config", "funktor.yml")
        template File.join("config", "ruby_layer.yml"), File.join(name, "config", "ruby_layer.yml")
        template File.join("config", "package.yml"), File.join(name, "config", "package.yml")
        template File.join("config", "environment.yml"), File.join(name, "config", "environment.yml")
      end

      def package_json
        template "package.json", File.join(name, "package.json")
      end

      def gemfile
        template "Gemfile", File.join(name, "Gemfile")
      end

      def gitignore
        template "gitignore", File.join(name, ".gitignore")
      end

      def resources
        template File.join("resources", "incoming_job_queue.yml"), File.join(name, "resources", "incoming_job_queue.yml")
        template File.join("resources", "incoming_job_queue_user.yml"), File.join(name, "resources", "incoming_job_queue_user.yml")
        template File.join("resources", "active_job_queue.yml"), File.join(name, "resources", "active_job_queue.yml")
        template File.join("resources", "cloudwatch_dashboard.yml"), File.join(name, "resources", "cloudwatch_dashboard.yml")
      end

      def iam_permissions
        template File.join("iam_permissions", "ssm.yml"), File.join(name, "iam_permissions", "ssm.yml")
        template File.join("iam_permissions", "incoming_job_queue.yml"), File.join(name, "iam_permissions", "incoming_job_queue.yml")
        template File.join("iam_permissions", "active_job_queue.yml"), File.join(name, "iam_permissions", "active_job_queue.yml")
      end

      def function_definitions
        template File.join("function_definitions", "active_job_handler.yml"), File.join(name, "function_definitions", "active_job_handler.yml")
        template File.join("function_definitions", "incoming_job_handler.yml"), File.join(name, "function_definitions", "incoming_job_handler.yml")
      end

      def lambda_handlers
        template File.join("handlers", "active_job_handler.rb"), File.join(name, "handlers", "active_job_handler.rb")
        template File.join("handlers", "incoming_job_handler.rb"), File.join(name, "handlers", "incoming_job_handler.rb")
      end

      def workers
        template File.join("workers", "hello_worker.rb"), File.join(name, "workers", "hello_worker.rb")
      end
    end
  end
end
