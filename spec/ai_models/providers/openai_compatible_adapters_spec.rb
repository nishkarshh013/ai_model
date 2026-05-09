require 'spec_helper'

RSpec.describe 'OpenAI-compatible adapters' do
  let(:messages) do
    [{ role: 'user', content: 'Explain Sidekiq' }]
  end

  shared_examples 'an openai-compatible provider' do |provider:, url:, api_key: nil, extra_config: {}, expected_headers: {}, endpoint: nil|
    before do
      AiModels.configure do |config|
        config.providers = {
          provider => { api_key: api_key, url: url }.compact.merge(extra_config)
        }
      end
    end

    it 'builds OpenAI-compatible chat requests and normalizes responses' do
      expected_request_headers = { 'Content-Type' => 'application/json' }.merge(expected_headers)
      expected_request_headers['Authorization'] = "Bearer #{api_key}" if api_key

      expected_endpoint = endpoint || "#{url}/chat/completions"

      stub_request(:post, expected_endpoint)
        .with(
          headers: expected_request_headers,
          body: {
            model: 'demo-model',
            messages: messages
          }.deep_stringify_keys
        )
        .to_return(
          status: 200,
          body: Oj.dump(
            {
              'model' => 'demo-model',
              'choices' => [
                {
                  'message' => { 'content' => 'Sidekiq is a background job processor.' },
                  'finish_reason' => 'stop'
                }
              ]
            }
          )
        )

      response = AiModels.chat(provider: provider, model: 'demo-model', messages: messages)

      expect(response).to be_a(AiModels::Response)
      expect(response.content).to eq('Sidekiq is a background job processor.')
      expect(response.model).to eq('demo-model')
      expect(response.finish_reason).to eq('stop')
    end

    it 'returns an enumerator for streaming mode' do
      stream = AiModels.chat_stream(provider: provider, model: 'demo-model', messages: messages)
      expect(stream).to be_a(Enumerator)
    end
  end

  include_examples(
    'an openai-compatible provider',
    provider: :groq,
    url: 'https://api.groq.com/openai/v1',
    api_key: 'secret',
    endpoint: 'https://api.groq.com/openai/v1/chat/completions'
  )

  include_examples(
    'an openai-compatible provider',
    provider: :lm_studio,
    url: 'http://localhost:1234/v1'
  )

  include_examples(
    'an openai-compatible provider',
    provider: :localai,
    url: 'http://localhost:8080/v1'
  )

  include_examples(
    'an openai-compatible provider',
    provider: :vllm,
    url: 'http://localhost:8000/v1'
  )

  include_examples(
    'an openai-compatible provider',
    provider: :openrouter,
    url: 'https://openrouter.ai/api/v1',
    api_key: 'secret',
    extra_config: { http_referer: 'https://example.com', x_title: 'MyApp' },
    expected_headers: { 'HTTP-Referer' => 'https://example.com', 'X-Title' => 'MyApp' }
  )
end
