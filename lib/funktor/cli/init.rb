module Funktor
  module CLI
    class Init < Thor::Group

      argument :directory, :desc => "The directory to initialize", :default => "funktor"

      def serverless_yml
        puts "#{directory}/serverless.yml"
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
