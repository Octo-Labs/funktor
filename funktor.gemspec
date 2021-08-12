$:.push File.expand_path("../lib", __FILE__)

require 'funktor/version'

Gem::Specification.new do |spec|
  spec.name          = "funktor"
  spec.version       = Funktor::VERSION
  spec.authors       = ["Jeremy Green"]
  spec.email         = ["jeremy@octolabs.com"]

  spec.summary       = %q{Background processing in AWS Lambda.}
  spec.description   = %q{Background processing in AWS Lambda.}
  spec.homepage      = "https://github.com/Octo-Labs/funktor"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Octo-Labs/funktor"
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk-sqs', '~> 1.37'
  spec.add_dependency 'aws-sdk-dynamodb', '~> 1.62'
  spec.add_dependency "activesupport" # TODO - Can we build our own verison of cattr_accessor to avoid this?
  spec.add_dependency "thor" # Thor drives the CLI TODO - should this just be a dev dependency?

  spec.add_development_dependency 'activejob', '>= 5.1.5'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'sinatra'
end
