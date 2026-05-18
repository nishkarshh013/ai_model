require 'faraday'
require 'logger'
require 'oj'
require 'securerandom'
require 'zeitwerk'
require 'active_support'
require 'active_support/core_ext'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'deepseek' => 'DeepSeek',
  'openai_compatible' => 'OpenAICompatible',
  'lm_studio' => 'LMStudio',
  'openrouter' => 'OpenRouter',
  'localai' => 'LocalAI',
  'vllm' => 'VLLM'
)
loader.ignore("#{__dir__}/generators")
loader.setup

module AiModels
  class << self
    def configure
      yield(configuration) if block_given?
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset!
      @configuration = Configuration.new
    end

    def chat(provider: nil, model:, messages:, **options)
      Client.new(provider: provider, model: model, **options).chat(messages: messages, **options)
    end

    def chat_stream(provider: nil, model:, messages:, **options, &block)
      client = Client.new(provider: provider, model: model, **options)

      if block_given?
        client.chat_stream(messages: messages, **options, &block)
        nil
      else
        client.chat_stream(messages: messages, **options)
      end
    end
  end
end

loader.eager_load if ENV['AI_MODELS_EAGER_LOAD'] == 'true'

require_relative 'ai_models/rails/railtie' if defined?(Rails::Railtie)
