module Funktor
  module CLI
    module Generate
      class WorkQueue < Thor::Group

        argument :name, :desc => "The name of the queue to generate"#, :default => "default"

        def resource_yml
          puts "queue-name.yml #{name}"
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


