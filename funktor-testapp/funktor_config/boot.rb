# Point at our Gemfile
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# load rubygems & bundler
require "rubygems"
require 'bundler/setup'

# Set up gems listed in the Gemfile.
Bundler.require(:default, :production)

# Here we load our development copy of funktor that we copy in using deploy-dev.sh
$LOAD_PATH.unshift 'funktor/lib'
require 'funktor'

# Load all ruby files in the app directory
Dir.glob( File.join('..', 'app', '**', '*.rb'), base: File.dirname(__FILE__) ).each do |ruby_file|
  puts "require_relative #{ruby_file}"
  require_relative ruby_file
end

