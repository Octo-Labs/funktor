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

      # register(class_name,      subcommand_alias, usage_list_string, description_string)
      register(Funktor::CLI::Init, "init", "init", "Initialize a new funktor directory")
      register(Funktor::CLI::Generate::Base, "generate", "generate", "Generate new resources")
    end
  end
end
