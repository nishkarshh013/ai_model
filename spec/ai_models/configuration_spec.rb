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
end
