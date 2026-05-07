module AiModels
  module Hooks
    class Context
      attr_reader :provider, :model, :messages, :request_payload
      attr_accessor :response, :error, :retry_count, :latency

      def initialize(provider:, model:, messages:, request_payload:, **attributes)
        @provider = provider
        @model = model
        @messages = messages
        @request_payload = request_payload
        @response = attributes.fetch(:response, nil)
        @error = attributes.fetch(:error, nil)
        @retry_count = attributes.fetch(:retry_count, 0)
        @latency = attributes.fetch(:latency, nil)
      end

      def to_h
        {
          provider: provider,
          model: model,
          messages: messages,
          request_payload: request_payload,
          response: response,
          error: error,
          retry_count: retry_count,
          latency: latency
        }
      end
    end
  end
end
