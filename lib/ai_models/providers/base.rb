module AiModels
  module Providers
    class Base
      include RequestErrorHandling
      include RequestLifecycle

      attr_reader :config, :global_config

      def initialize(config:, global_config:)
        @config = (config || {}).deep_symbolize_keys
        @global_config = global_config
      end

      def chat(messages:, model:, stream: false, **options, &block)
        raise NotImplementedError, 'Provider must implement #chat'
      end

      private

      def build_connection(url)
        Faraday.new(url: url) do |builder|
          builder.headers['Content-Type'] = 'application/json'
          global_config.middleware.apply(builder, global_config: global_config, provider: provider_key)
          builder.adapter Faraday.default_adapter
        end
      end

      def request_options
        {
          timeout: global_config.timeout,
          open_timeout: global_config.open_timeout
        }
      end

      def parse_json(body)
        return {} if body.nil? || body.empty?

        Oj.load(body)
      rescue Oj::ParseError => e
        raise Errors::ProviderError.new("Unable to parse provider response: #{e.message}", raw: body)
      end

      def encode_json(payload)
        serializable_payload =
          if payload.respond_to?(:deep_stringify_keys)
            payload.deep_stringify_keys
          else
            payload
          end

        Oj.dump(serializable_payload, mode: :compat)
      end

      def handle_http_errors!(response)
        return response if response.success?

        raw = parse_json_safely(response.body)
        message = extract_error_message(raw) || "Provider request failed with status #{response.status}"

        error_class =
          case response.status
          when 401, 403 then Errors::AuthenticationError
          when 429 then Errors::RateLimitError
          else Errors::ProviderError
          end

        raise error_class.new(message, status: response.status, raw: raw || response.body)
      end

      def parse_json_safely(body)
        parse_json(body)
      rescue Errors::ProviderError
        nil
      end

      def extract_error_message(payload)
        return payload if payload.is_a?(String)
        return 'Unknown provider error' unless payload.respond_to?(:[])

        extract_message_from_payload_hash(payload)
      end

      def normalize_tokens(usage)
        return unless usage.is_a?(Hash)

        usage.deep_symbolize_keys
      end

      def provider_key
        self.class.name.split('::').last.underscore.to_sym
      end

      def extract_message_from_payload_hash(payload)
        error = payload['error']
        return extract_hash_error_message(error, payload) if error.is_a?(Hash)
        return error.to_s if error
        return payload['message'].to_s if payload['message']

        payload.inspect
      end

      def extract_hash_error_message(error, payload)
        error['message'] || payload['message'] || payload.inspect
      end
    end
  end
end
