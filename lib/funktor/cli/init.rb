module Funktor
  module CLI
    class Init < Thor::Group

      argument :framework, :desc => "The deployment/provisioning framework to use. Defaults to 'serverless'", :default => "serverless"
      class_option :directory, :aliases => "-d",
        :type => :string, :desc => "The directory to initialize",
        :default => "funktor"

      desc <<-DESC
        Description:
          Initialize a new funktor deployment directory.
      DESC

      def serverless_yml
        puts "#{options[:directory]}/serverless.yml"
      end

      def package_json
        puts "package.json"
      end

      def gemfile
        puts "Gemfile"
      end

      def dockerfile
        puts "Dockerfile"
      end

      def build_image_rb
        puts "build_image.rb"
      end

      def image_console_rb
        puts "image_console.rb"
      end

    end
  end
end
