require 'spec_helper'

RSpec.describe 'retry backoff' do
  before do
    test_provider = Class.new(AiModels::Providers::Base) do
      def chat(messages:, model:, stream: false, **options)
        payload = {
          model: model,
          messages: messages,
          stream: stream
        }.merge(options)

        with_request_lifecycle(model: model, messages: messages, request_payload: payload) do
          raise Faraday::ConnectionFailed, 'down'
        end
      end

      private

      def provider_key
        :retry_backoff_test
      end
    end

    AiModels::Providers::Registry.register(:retry_backoff_test, test_provider)
  end

  let(:messages) do
    [{ role: 'user', content: 'Hello' }]
  end

  it 'sleeps using default exponential backoff between retries' do
    AiModels.configure do |config|
      config.max_retries = 2
      config.providers = { retry_backoff_test: {} }
    end

    delays = []
    allow_any_instance_of(
      AiModels::Providers::Registry.fetch(:retry_backoff_test)
    ).to receive(:sleep) do |_instance, seconds|
      delays << seconds
      nil
    end

    expect do
      AiModels.chat(provider: :retry_backoff_test, model: 'demo', messages: messages)
    end.to raise_error(AiModels::Errors::ConnectionError)

    expect(delays).to eq([0.5, 1.0])
  end

  it 'supports a custom backoff strategy' do
    AiModels.configure do |config|
      config.max_retries = 1
      config.retry_backoff = ->(_attempt) { 0.123 }
      config.providers = { retry_backoff_test: {} }
    end

    expect_any_instance_of(AiModels::Providers::Registry.fetch(:retry_backoff_test)).to receive(:sleep).with(0.123)

    expect do
      AiModels.chat(provider: :retry_backoff_test, model: 'demo', messages: messages)
    end.to raise_error(AiModels::Errors::ConnectionError)
  end
end
