module AiModels
  module Providers
    class LMStudio < OpenAICompatible
      DEFAULT_URL = 'http://localhost:1234/v1'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end
    end
  end
end
