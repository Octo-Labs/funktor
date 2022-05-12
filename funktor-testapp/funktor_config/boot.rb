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


Funktor.enable_work_queue_visibility = false

# Load all ruby files in the app directory
require_rel File.join('..', 'app')

