# Point at our Gemfile
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# load rubygems & bundler
require "rubygems"
require 'bundler/setup'

# Set up gems listed in the Gemfile.
Bundler.require(:default, :production)

# Load all ruby files in the app directory
Dir.glob( File.join('..', 'app', '**', '*.rb'), base: File.dirname(__FILE__) ).each do |ruby_file|
  puts "require_relative #{ruby_file}"
  require_relative ruby_file
end

