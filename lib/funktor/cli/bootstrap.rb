module Funktor
  module CLI
    class Bootstrap < Thor::Group
      include Thor::Actions

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The bootstrap file to generate.",
        :default => "funktor.yml"
      class_option :directory, :aliases => "-d",
        :type => :string, :desc => "The directory to initialize",
        :default => "funktor"

      desc <<~DESC
        Description:
          Bootstrap a new funktor application by generating a funktor.yml file."
      DESC

      def self.source_root
        File.dirname(__FILE__)
      end

      def funktor_yml
        puts funktor_file_target
        template "templates/funktor.yml", funktor_file_target
      end

      private
      def funktor_file_target
        File.join options[:directory], options[:file]
      end

    end
  end
end

