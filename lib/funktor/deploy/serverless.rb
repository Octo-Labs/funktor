module Funktor
  module Deploy
    class Serverless
      attr_accessor :file, :tmp_dir_prefix, :verbose, :stage
      def initialize(file:, tmp_dir_prefix:, verbose:, stage:)
        @file = file
        @tmp_dir_prefix = tmp_dir_prefix
        @verbose = verbose
        @stage = stage
      end

      def call
        puts "deploying file #{file} via tmp_dir_prefix #{tmp_dir_prefix} for stage #{stage}"
        make_tmp_dir
        create_serverless_file
      end

      def funktor_data
        @funktor_data ||= squash_hash(YAML.load_file(file))
      end

      def squash_hash(hsh, stack=[])
        hsh.reduce({}) do |res, (key, val)|
          next_stack = [ *stack, key ]
          if val.is_a?(Hash)
            next res.merge(squash_hash(val, next_stack))
          end
          res.merge(next_stack.join(".").to_sym => val)
        end
      end

      def make_tmp_dir
        FileUtils.mkdir_p tmp_dir
      end

      def tmp_dir
        "#{tmp_dir_prefix}_#{stage}"
      end

      def create_serverless_file
        puts "funktor_data = "
        puts funktor_data
        template_source = File.open(serverless_file_source).read
        file_content = template_source % funktor_data
        File.open(serverless_file_destination, 'w') { |file| file.write(file_content) }
      end

      def serverless_file_source
        File.expand_path("../serverless_templates/serverless.yml", __FILE__)
      end

      def serverless_file_destination
        File.join tmp_dir, 'serverless.yml'
      end
    end
  end
end

