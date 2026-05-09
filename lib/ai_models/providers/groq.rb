module AiModels
  module Providers
    class Groq < OpenAICompatible
      DEFAULT_URL = 'https://api.groq.com/openai/v1'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end
    end
  end
end
