module AiModels
  module Providers
    module RequestErrorHandling
      private

      def normalize_exception(exception, context:)
        return exception if exception.is_a?(Errors::BaseError)

        request_metadata = request_metadata_for(context)

        case exception
        when Faraday::TimeoutError
          build_transport_error(
            Errors::TimeoutError,
            "Request to #{context.provider} timed out",
            context,
            request_metadata,
            exception
          )
        when Faraday::ConnectionFailed, SocketError, SystemCallError
          build_transport_error(
            Errors::ConnectionError,
            "Unable to connect to #{context.provider}",
            context,
            request_metadata,
            exception
          )
        when Faraday::Error
          build_transport_error(
            Errors::ProviderError,
            exception.message,
            context,
            request_metadata,
            exception
          )
        else
          exception
        end
      end

      def request_metadata_for(context)
        {
          request_id: context.request_id,
          model: context.model,
          messages: context.messages,
          request_payload: context.request_payload
        }
      end

      def build_transport_error(error_class, message, context, request_metadata, exception)
        error_class.new(
          message,
          provider: context.provider,
          retry_count: context.retry_count,
          request_metadata: request_metadata,
          original_exception: exception
        )
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

          delay = retry_backoff_delay(attempts - 1)
          sleep(delay) if delay.positive?
          return nil
        end

        handle_terminal_error(context, error, started_at)
      end

      def retry_backoff_delay(attempt)
        backoff = global_config.respond_to?(:retry_backoff) ? global_config.retry_backoff : nil
        delay = backoff.respond_to?(:call) ? backoff.call(attempt) : 0
        delay = delay.to_f
        delay.negative? ? 0.0 : delay
      rescue StandardError
        0.0
      end

      def handle_terminal_error(context, error, started_at)
        context.error = error
        context.latency ||= current_time - started_at
        run_hook(:on_error, context)
        if error.respond_to?(:original_exception) && error.original_exception
          raise error, cause: error.original_exception
        end

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
