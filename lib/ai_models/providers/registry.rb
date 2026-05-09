module AiModels
  module Providers
    module Registry
      class << self
        def fetch(name)
          providers.fetch(name.to_sym) do
            raise Errors::ProviderError, "Unknown provider: #{name}"
          end
        end

        def register(name, provider_class)
          providers[name.to_sym] = provider_class
        end

        def all
          providers.dup
        end

        private

        def providers
          @providers ||= {
            ollama: Ollama,
            deepseek: DeepSeek,
            openai: OpenAICompatible,
            groq: Groq,
            lm_studio: LMStudio,
            openrouter: OpenRouter,
            localai: LocalAI,
            vllm: VLLM
          }
        end
      end
    end
  end
end
