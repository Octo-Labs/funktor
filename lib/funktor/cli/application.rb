require "thor"

require_relative "./init"
require_relative "./generate/base"

module Funktor
  module CLI
    class Application < Thor
      # This makes thor report the correct exit code in the event of a failure.
      def self.exit_on_failure?
        true
      end

      register(Funktor::CLI::Init, "init", "init [DIRECTORY]", "Initialize a new funktor directory")
      register(Funktor::CLI::Generate::Base, "generate", "generate GENERATOR [args] [options]", "Generate new resources")

      # Set up an alias so that "funktor g" is the same as "funktor generate"
      map "g" => :generate
    end
  end
end
