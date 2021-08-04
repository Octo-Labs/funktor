module Funktor
  module CLI
    class Bootstrap < Thor::Group
      include Thor::Actions

      argument :name, :type => :string, :desc => "The name of the app to initialize"

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The bootstrap file to generate.",
        :default => "funktor_init.yml"

      class_option :directory, :aliases => "-d",
        :type => :string, :desc => "The directory in which to place the bootstrap file.",
        :default => nil

      desc <<~DESC
        Description:
          Bootstrap a new funktor application by generating a funktor_init.yml file."
      DESC

      def self.source_root
        File.dirname(__FILE__)
      end

      def funktor_yml
        # TODO - Should we camelize the app name before writing it into the config? (CloudFormation names get weird with underscores and dashes.)
        template "templates/funktor_init.yml", funktor_file_target
      end

      private
      def funktor_file_target
        File.join funktor_directory_target, options[:file]
      end

      def funktor_directory_target
        options[:directory] || name
      end

    end
  end
end

