module Funktor
  module CLI
    class Bootstrap < Thor::Group
      include Thor::Actions

      argument :name, :type => :string, :desc => "The name of the app to initialize"

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The bootstrap file to generate.",
        :default => "funktor.yml"

      desc <<~DESC
        Description:
          Bootstrap a new funktor application by generating a funktor.yml file."
      DESC

      def self.source_root
        File.dirname(__FILE__)
      end

      def funktor_yml
        # TODO - Should we camelize the app name before writing it into the config? (CloudFormation names get weird with underscores and dashes.)
        puts funktor_file_target
        template "templates/funktor.yml", funktor_file_target
      end

      private
      def funktor_file_target
        File.join name, options[:file]
      end

    end
  end
end

