module Funktor
  module Deploy
    class Serverless
      def call(file:, tmp_dir:, verbose:)
        puts "deploying file #{file} via tmp_dir #{tmp_dir}"

      end
    end
  end
end

