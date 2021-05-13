module Funktor
  module CLI
    module Generate
      class WorkQueue < Thor::Group

        def resource_yml
          puts "queue-name.yml"
        end

        def lambda_handler
          puts "handler.rb"
        end

        def function_definition
          puts "function_definition.yml"
        end

      end
    end
  end
end


