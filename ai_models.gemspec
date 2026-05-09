require_relative 'lib/ai_models/version'

Gem::Specification.new do |spec|
  spec.name = 'ai_models'
  spec.version = AiModels::VERSION
  spec.summary = 'Rails-native abstraction layer for AI and LLM providers'
  spec.description = 'Production-grade provider abstraction for chat and streaming across local and hosted AI backends.'
  spec.authors = ['Your Name']
  spec.email = ['you@example.com']
  spec.license = 'MIT'
  spec.files = Dir.glob('lib/**/*') + ['README.md']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'faraday'
  spec.add_dependency 'oj'
  spec.add_dependency 'zeitwerk'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'pry'
end
