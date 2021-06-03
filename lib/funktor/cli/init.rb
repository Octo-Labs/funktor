module Funktor
  module CLI
    class Init < Thor::Group
      include Thor::Actions

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

      def self.source_root
        File.join File.dirname(__FILE__), 'templates'
      end

      def self.destination_root
        options[:directory]
      end

      def serverless_yml
        template "serverless.yml", File.join(options[:directory], "serverless.yml")
      end

      def funktor_config_yml
        template "funktor_config.yml", File.join(options[:directory], "funktor_config.yml")
      end

      def package_json
        template "package.json", File.join(options[:directory], "package.json")
      end

      def gemfile
        template "Gemfile", File.join(options[:directory], "Gemfile")
      end

      def gitignore
        template "gitignore", File.join(options[:directory], ".gitignore")
      end

      def resources
        template File.join("resources", "incoming_job_queue.yml"), File.join(options[:directory], "resources", "incoming_job_queue.yml")
        template File.join("resources", "incoming_job_queue_user.yml"), File.join(options[:directory], "resources", "incoming_job_queue_user.yml")
        template File.join("resources", "active_job_queue.yml"), File.join(options[:directory], "resources", "active_job_queue.yml")
        template File.join("resources", "cloudwatch_dashboard.yml"), File.join(options[:directory], "resources", "cloudwatch_dashboard.yml")
      end

      def lambda_handlers
        template File.join("handlers", "active_job_handler.rb"), File.join(options[:directory], "handlers", "active_job_handler.rb")
        template File.join("handlers", "incoming_job_handler.rb"), File.join(options[:directory], "handlers", "incoming_job_handler.rb")
      end

      def workers
        template File.join("workers", "hello_worker.rb"), File.join(options[:directory], "workers", "hello_worker.rb")
      end
    end
  end
end
