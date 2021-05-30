module Funktor
  module CLI
    class Bootstrap < Thor::Group

      class_option :file, :aliases => "-f",
        :type => :string, :desc => "The bootstrap file to generate.",
        :default => "funktor.yml"

      desc <<~DESC
        Description:
          Bootstrap a new funktor application by generating a funktor.yml file."
      DESC

      def funktor_yml
        puts options[:file]
      end

    end
  end
end

