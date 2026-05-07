module AiModels
  module Providers
    class DeepSeek < OpenAICompatible
      DEFAULT_URL = 'https://api.deepseek.com'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end
    end
  end
end
