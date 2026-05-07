module AiModels
  module Errors
    class BaseError < StandardError
      attr_reader :status, :raw

      def initialize(message = nil, status: nil, raw: nil)
        @status = status
        @raw = raw
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
