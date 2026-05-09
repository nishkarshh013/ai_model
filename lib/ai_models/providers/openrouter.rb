module AiModels
  module Providers
    class OpenRouter < OpenAICompatible
      DEFAULT_URL = 'https://openrouter.ai/api/v1'

      private

      def base_url
        config[:url] || DEFAULT_URL
      end

      def custom_headers
        headers = super.dup

        http_referer = config[:http_referer]
        x_title = config[:x_title]

        headers['HTTP-Referer'] = http_referer if http_referer.present?
        headers['X-Title'] = x_title if x_title.present?

        headers
      end
    end
  end
end
