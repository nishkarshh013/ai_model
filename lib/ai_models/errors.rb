module AiModels
  module Errors
    class BaseError < StandardError
      attr_reader :status, :raw, :provider, :retry_count, :request_metadata, :original_exception

      def initialize(
        message = nil,
        status: nil,
        raw: nil,
        provider: nil,
        retry_count: nil,
        request_metadata: nil,
        original_exception: nil
      )
        @status = status
        @raw = raw
        @provider = provider
        @retry_count = retry_count
        @request_metadata = request_metadata
        @original_exception = original_exception
        super(message)
      end
    end

    class ConnectionError < BaseError; end
    class AuthenticationError < BaseError; end
    class RateLimitError < BaseError; end
    class TimeoutError < BaseError; end
    class ProviderError < BaseError; end
  end
end
