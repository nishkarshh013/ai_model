module AiModels
  module Providers
    module RequestLifecycle
      private

      def with_request_lifecycle(model:, messages:, request_payload:)
        context = Hooks::Context.new(
          provider: provider_key,
          model: model,
          messages: messages,
          request_payload: request_payload,
          request_id: SecureRandom.uuid
        )
        attempts = 0

        loop do
          attempts += 1
          started_at = current_time
          prepare_request_context!(context, attempts)
          run_hook(:before_request, context)

          begin
            response = yield(context)
            finalize_successful_request(context, response, started_at)
            return response
          rescue StandardError => e
            handle_request_exception(context, e, attempts, started_at)
          rescue Errors::BaseError => e
            handle_terminal_error(context, e, started_at)
          end
        end
      end

      def prepare_request_context!(context, attempts)
        context.response = nil
        context.error = nil
        context.retry_count = attempts - 1
        context.latency = nil
      end

      def finalize_successful_request(context, response, started_at)
        context.response = response
        context.latency = current_time - started_at
        run_hook(:after_response, context)
      end

      def handle_request_exception(context, exception, attempts, started_at)
        converted = normalize_exception(exception, context: context)

        if converted.is_a?(Errors::TimeoutError) || converted.is_a?(Errors::ConnectionError)
          handle_retry_or_error(context, converted, attempts, started_at)
        elsif converted.is_a?(Errors::BaseError)
          handle_terminal_error(context, converted, started_at)
        else
          raise
        end
      end
    end
  end
end
