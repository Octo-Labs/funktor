module Funktor
  module CLI
    class Init < Thor::Group

      class_option :framework, :aliases => "-f",
        :type => :string, :desc => "The deployment/provisioning framework to use.",
        :default => "serverless"
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
        puts "#{options[:directory]}/package.json"
      end

      def gemfile
        puts "#{options[:directory]}/Gemfile"
      end

      def dockerfile
        puts "#{options[:directory]}/Dockerfile"
      end

      def build_image_rb
        puts "#{options[:directory]}/build_image.rb"
      end

      def image_console_rb
        puts "#{options[:directory]}/image_console.rb"
      end

    end
  end
end
