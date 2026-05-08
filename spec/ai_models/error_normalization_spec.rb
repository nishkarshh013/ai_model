require 'spec_helper'

RSpec.describe 'exception normalization' do
  before do
    test_provider = Class.new(AiModels::Providers::Base) do
      def chat(messages:, model:, stream: false, **options)
        payload = {
          model: model,
          messages: messages,
          stream: stream
        }.merge(options)

        with_request_lifecycle(model: model, messages: messages, request_payload: payload) do
          case config[:mode]
          when :connection_failed
            raise Faraday::ConnectionFailed, 'dial tcp failed'
          when :timeout
            raise Faraday::TimeoutError, 'read timeout'
          when :errno_refused
            raise Errno::ECONNREFUSED, 'Connection refused'
          when :always_connection_failed
            raise Faraday::ConnectionFailed, 'still down'
          else
            raise 'unknown mode'
          end
        end
      end

      private

      def provider_key
        :normalization_test
      end
    end

    AiModels::Providers::Registry.register(:normalization_test, test_provider)
  end

  let(:messages) do
    [{ role: 'user', content: 'Hello' }]
  end

  it 'maps Faraday::ConnectionFailed into AiModels::Errors::ConnectionError with metadata and cause' do
    AiModels.configure do |config|
      config.max_retries = 0
      config.providers = { normalization_test: { mode: :connection_failed } }
    end

    expect do
      AiModels.chat(provider: :normalization_test, model: 'demo', messages: messages, temperature: 0.7)
    end.to raise_error(AiModels::Errors::ConnectionError) { |error|
      expect(error.provider).to eq(:normalization_test)
      expect(error.retry_count).to eq(0)
      expect(error.request_metadata).to include(model: 'demo', messages: messages)
      expect(error.request_metadata[:request_payload]).to include(temperature: 0.7)
      expect(error.original_exception).to be_a(Faraday::ConnectionFailed)
      expect(error.cause).to be_a(Faraday::ConnectionFailed)
      expect(error.message).to include('Unable to connect')
    }
  end

  it 'maps Faraday::TimeoutError into AiModels::Errors::TimeoutError with metadata and cause' do
    AiModels.configure do |config|
      config.max_retries = 0
      config.providers = { normalization_test: { mode: :timeout } }
    end

    expect do
      AiModels.chat(provider: :normalization_test, model: 'demo', messages: messages)
    end.to raise_error(AiModels::Errors::TimeoutError) { |error|
      expect(error.provider).to eq(:normalization_test)
      expect(error.retry_count).to eq(0)
      expect(error.original_exception).to be_a(Faraday::TimeoutError)
      expect(error.cause).to be_a(Faraday::TimeoutError)
      expect(error.message).to include('timed out')
    }
  end

  it 'maps Errno::* connection failures into AiModels::Errors::ConnectionError' do
    AiModels.configure do |config|
      config.max_retries = 0
      config.providers = { normalization_test: { mode: :errno_refused } }
    end

    expect do
      AiModels.chat(provider: :normalization_test, model: 'demo', messages: messages)
    end.to raise_error(AiModels::Errors::ConnectionError) { |error|
      expect(error.original_exception).to be_a(Errno::ECONNREFUSED)
      expect(error.cause).to be_a(Errno::ECONNREFUSED)
    }
  end

  it 'does not leak raw Faraday exceptions across thread boundaries' do
    AiModels.configure do |config|
      config.max_retries = 0
      config.providers = { normalization_test: { mode: :connection_failed } }
    end

    thread = Thread.new do
      AiModels.chat(provider: :normalization_test, model: 'demo', messages: messages)
      :ok
    rescue StandardError => e
      e
    end

    result = thread.value

    expect(result).to be_a(AiModels::Errors::ConnectionError)
    expect(result.original_exception).to be_a(Faraday::ConnectionFailed)
  end

  it 'raises a normalized error after retry exhaustion' do
    AiModels.configure do |config|
      config.max_retries = 1
      config.providers = { normalization_test: { mode: :always_connection_failed } }
    end

    expect do
      AiModels.chat(provider: :normalization_test, model: 'demo', messages: messages)
    end.to raise_error(AiModels::Errors::ConnectionError) { |error|
      expect(error.retry_count).to eq(1)
      expect(error.provider).to eq(:normalization_test)
      expect(error.original_exception).to be_a(Faraday::ConnectionFailed)
      expect(error.cause).to be_a(Faraday::ConnectionFailed)
    }
  end
end
