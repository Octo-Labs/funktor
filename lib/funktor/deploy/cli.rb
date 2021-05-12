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
          tmp_dir_prefix: '.funktor',
          stage: 'dev'
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
          opts.on('-t', '--tmp_dir_prefix=TMP_DIR_PREFIX', 'The prefix for the tmp dir. The stage will be appended.') do |tmp_dir_prefix|
            options[:tmp_dir_prefix] = tmp_dir_prefix
          end
          opts.on('-s', '--stage=STAGE', 'The stage to deploy to. Defaults to "dev"') do |stage|
            options[:stage] = stage
          end
          opts.on('-h') { puts opts; exit }
          opts.parse!(argv)
        end
      end

      def run
        Funktor::Deploy::Serverless.new(**options).call
      end
    end
  end
end

