module AiModels
  module Hooks
    class Context
      attr_reader :provider, :model, :messages, :request_payload, :request_id
      attr_accessor :response, :error, :retry_count, :latency

      def initialize(provider:, model:, messages:, request_payload:, **attributes)
        @provider = provider
        @model = model
        @messages = messages
        @request_payload = request_payload
        @request_id = attributes.fetch(:request_id)
        @response = attributes.fetch(:response, nil)
        @error = attributes.fetch(:error, nil)
        @retry_count = attributes.fetch(:retry_count, 0)
        @latency = attributes.fetch(:latency, nil)
      end

      def attempt
        retry_count.to_i + 1
      end

      def stream?
        !!(request_payload[:stream] || request_payload['stream'])
      end

      def to_h
        {
          provider: provider,
          model: model,
          messages: messages,
          request_payload: request_payload,
          request_id: request_id,
          response: response,
          error: error,
          retry_count: retry_count,
          latency: latency,
          attempt: attempt,
          stream: stream?
        }
      end
    end
  end
end
