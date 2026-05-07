require 'spec_helper'

RSpec.describe AiModels do
  let(:messages) do
    [{ role: 'user', content: 'Hello' }]
  end

  describe '.chat' do
    it 'uses the configured default provider when none is given' do
      provider_class = Class.new do
        def initialize(config:, global_config:)
          @config = config
          @global_config = global_config
        end

        def chat(messages:, model:, stream: false, **)
          AiModels::Response.new(
            content: "#{model}:#{messages.first[:content]}:#{stream}",
            raw: { config: @config, default_provider: @global_config.default_provider }
          )
        end
      end

      AiModels::Providers::Registry.register(:test_default, provider_class)
      AiModels.configure do |config|
        config.default_provider = :test_default
        config.providers = {
          test_default: {
            api_key: 'unused'
          }
        }
      end

      response = AiModels.chat(model: 'demo-model', messages: messages)

      expect(response.content).to eq('demo-model:Hello:false')
      expect(response.raw[:config]).to eq(api_key: 'unused')
    end
  end

  describe '.chat_stream' do
    it 'returns an enumerator when no block is given' do
      provider_class = Class.new do
        def initialize(config:, global_config:); end

        def chat(messages:, model:, stream: false, **)
          raise 'expected stream mode' unless stream

          Enumerator.new do |yielder|
            yielder << AiModels::Response.new(content: "#{model}:#{messages.first[:content]}-1")
            yielder << AiModels::Response.new(content: "#{model}:#{messages.first[:content]}-2")
          end
        end
      end

      AiModels::Providers::Registry.register(:stream_test, provider_class)

      stream = AiModels.chat_stream(
        provider: :stream_test,
        model: 'demo-model',
        messages: messages
      )

      expect(stream.map(&:content)).to eq(['demo-model:Hello-1', 'demo-model:Hello-2'])
    end

    it 'yields normalized chunks when a block is given' do
      provider_class = Class.new do
        def initialize(config:, global_config:); end

        def chat(messages:, model:, stream: false, &block)
          raise 'expected stream mode' unless stream

          block.call(AiModels::Response.new(content: "#{model}:#{messages.first[:content]}-1"))
          block.call(AiModels::Response.new(content: "#{model}:#{messages.first[:content]}-2"))
        end
      end

      AiModels::Providers::Registry.register(:stream_callback_test, provider_class)

      chunks = []

      result = AiModels.chat_stream(
        provider: :stream_callback_test,
        model: 'demo-model',
        messages: messages
      ) do |chunk|
        chunks << chunk.content
      end

      expect(result).to be_nil
      expect(chunks).to eq(['demo-model:Hello-1', 'demo-model:Hello-2'])
    end
  end
end
