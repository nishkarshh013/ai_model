require 'spec_helper'

RSpec.describe AiModels::Configuration do
  describe 'defaults' do
    it 'uses sensible production defaults' do
      configuration = described_class.new

      expect(configuration.default_provider).to eq(:ollama)
      expect(configuration.timeout).to eq(60)
      expect(configuration.open_timeout).to eq(10)
      expect(configuration.max_retries).to eq(2)
      expect(configuration.provider_config(:ollama)).to eq({})
      expect(configuration.middleware.entries.map(&:middleware)).to eq(
        [AiModels::Middleware::Retry, AiModels::Middleware::Logging]
      )
    end

    it 'starts with an empty lifecycle hook registry' do
      configuration = described_class.new

      expect(configuration.hooks.register(:before_request)).to eq([])
      expect(configuration.hooks.register(:after_response)).to eq([])
      expect(configuration.hooks.register(:on_error)).to eq([])
      expect(configuration.hooks.register(:on_retry)).to eq([])
    end
  end

  describe '#providers=' do
    it 'deep symbolises provider configuration' do
      configuration = described_class.new

      configuration.providers = {
        'deepseek' => {
          'api_key' => 'token',
          'headers' => {
            'X-Test' => '1'
          }
        }
      }

      expect(configuration.provider_config(:deepseek)).to eq(
        api_key: 'token',
        headers: { 'X-Test': '1' }
      )
    end
  end

  describe 'lifecycle hook registration' do
    it 'registers public request lifecycle callbacks' do
      configuration = described_class.new

      configuration.before_request { |_context| :before }
      configuration.after_response { |_context| :after }
      configuration.on_error { |_context| :error }
      configuration.on_retry { |_context| :retry }

      expect(configuration.hooks.register(:before_request).size).to eq(1)
      expect(configuration.hooks.register(:after_response).size).to eq(1)
      expect(configuration.hooks.register(:on_error).size).to eq(1)
      expect(configuration.hooks.register(:on_retry).size).to eq(1)
    end
  end
end
