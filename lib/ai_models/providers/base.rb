module AiModels
  module Providers
    class Base
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

      def with_request_lifecycle(model:, messages:, request_payload:)
        context = Hooks::Context.new(
          provider: provider_key,
          model: model,
          messages: messages,
          request_payload: request_payload
        )
        attempts = 0

        loop do
          attempts += 1
          started_at = current_time
          context.response = nil
          context.error = nil
          context.retry_count = attempts - 1
          context.latency = nil

          run_hook(:before_request, context)

          begin
            response = yield(context)
            context.response = response
            context.latency = current_time - started_at
            run_hook(:after_response, context)
            return response
          rescue Faraday::TimeoutError => e
            converted = Errors::TimeoutError.new(e.message)
            handle_retry_or_error(context, converted, attempts, started_at)
          rescue Faraday::ConnectionFailed => e
            converted = Errors::ConnectionError.new(e.message)
            handle_retry_or_error(context, converted, attempts, started_at)
          rescue Faraday::Error => e
            handle_terminal_error(context, Errors::ProviderError.new(e.message), started_at)
          rescue Errors::BaseError => e
            handle_terminal_error(context, e, started_at)
          end
        end
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

        return "Unknown provider error" unless payload.respond_to?(:[])

        error = payload["error"]

        if error.is_a?(Hash)
          error["message"] ||
            payload["message"] ||
            payload.inspect
        elsif error
          error.to_s
        elsif payload["message"]
          payload["message"].to_s
        else
          payload.inspect
        end
      end

      def normalize_tokens(usage)
        return unless usage.is_a?(Hash)

        usage.deep_symbolize_keys
      end

      def provider_key
        self.class.name.split('::').last.underscore.to_sym
      end

      def retryable_exception?(attempts)
        attempts <= global_config.max_retries.to_i
      end

      def handle_retry_or_error(context, error, attempts, started_at)
        context.error = error
        context.latency = current_time - started_at

        if retryable_exception?(attempts)
          context.retry_count = attempts
          run_hook(:on_retry, context)
          return nil
        end

        handle_terminal_error(context, error, started_at)
      end

      def handle_terminal_error(context, error, started_at)
        context.error = error
        context.latency ||= current_time - started_at
        run_hook(:on_error, context)
        raise error
      end

      def run_hook(event, context)
        global_config.hooks.run(event, context, logger: global_config.logger)
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
