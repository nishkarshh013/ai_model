require_relative 'lib/ai_models/version'

Gem::Specification.new do |spec|
  spec.name = 'ai_models'
  spec.version = AiModels::VERSION

  spec.summary = 'Rails-native abstraction layer for AI and LLM providers'

  spec.description = <<~DESCRIPTION
    ai_models is a Rails-native AI infrastructure layer that provides
    unified chat APIs, streaming, provider abstraction, hooks, middleware,
    and local AI support across Ollama, LM Studio, DeepSeek,
    and OpenAI-compatible providers.
  DESCRIPTION

  spec.authors = ['Nishkarsh Sahu']
  spec.email = ['nishkarshsahu007@gmail.com']

  spec.homepage = 'https://github.com/nishkarshh013/ai_models'
  spec.license = 'MIT'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/nishkarshh013/ai_models',
    'source_code_uri' => 'https://github.com/nishkarshh013/ai_models',
    'changelog_uri' => 'https://github.com/nishkarshh013/ai_models/blob/main/CHANGELOG.md'
  }

  spec.files = Dir.glob('lib/**/*') + [
    'README.md',
    'LICENSE',
    'CHANGELOG.md'
  ]

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