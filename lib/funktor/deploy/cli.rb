require 'optparse'
require 'funktor/deploy/serverless'

module Funktor
  module Deploy
    class CLI
      attr_reader :options
      def initialize
        @options = {
          verbose: false,
          file: 'funktor.yml',
          tmp_dir: '.funktor'
        }
      end

      def parse(argv = ARGV)
        OptionParser.new do |opts|
          opts.on('-v', '--verbose', 'Display verbose output') do |verbose|
            options[:verbose] = verbose
          end
          opts.on('-f', '--file=FILE', 'The path to the funktor.yml file to deploy') do |file|
            options[:file] = file
          end
          opts.on('-t', '--tmp_dir=TMP_DIR', 'The path to the funktor.yml file to deploy') do |tmp_dir|
            options[:tmp_dir] = tmp_dir
          end
          opts.on('-h') { puts opts; exit }
          opts.parse!
        end
      end

      def run
        Funktor::Deploy::Serverless.new.call(**options)
      end
    end
  end
end

