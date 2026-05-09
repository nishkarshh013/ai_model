module AiModels
  module Providers
    class VLLM < OpenAICompatible
      DEFAULT_URL = 'http://localhost:8000/v1'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end
    end
  end
end
