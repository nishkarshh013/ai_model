module AiModels
  module Providers
    class LocalAI < OpenAICompatible
      DEFAULT_URL = 'http://localhost:8080/v1'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end
    end
  end
end
