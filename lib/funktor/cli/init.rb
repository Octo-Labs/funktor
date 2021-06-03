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

    end
  end
end
