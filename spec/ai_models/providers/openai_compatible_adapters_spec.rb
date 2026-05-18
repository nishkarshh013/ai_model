require 'spec_helper'

RSpec.describe 'OpenAI-compatible adapters' do
  let(:messages) do
    [{ role: 'user', content: 'Explain Sidekiq' }]
  end

  shared_examples 'an openai-compatible provider' do
    let(:provider_api_key) { nil }
    let(:provider_extra_config) { {} }
    let(:provider_expected_headers) { {} }
    let(:provider_endpoint) { nil }

    before do
      AiModels.configure do |config|
        config.providers = {
          provider_name => { api_key: provider_api_key, url: provider_url }.compact.merge(provider_extra_config)
        }
      end
    end

    it 'builds OpenAI-compatible chat requests and normalizes responses' do
      expected_endpoint = provider_endpoint || "#{provider_url}/chat/completions"
      expected_body = {
        model: 'demo-model',
        messages: messages
      }.deep_stringify_keys

      captured_headers = nil

      stub_request(:post, expected_endpoint)
        .with(
          &lambda do |request|
            captured_headers = request.headers
            parsed_body = Oj.load(request.body)

            normalized_headers = captured_headers.each_with_object({}) do |(key, value), acc|
              acc[key.to_s.downcase] = value
            end

            content_type = normalized_headers['content-type'].to_s
            has_json_content_type = content_type.include?('application/json')

            parsed_body == expected_body && has_json_content_type
          end
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

      client = AiModels::Client.new(provider: provider_name, model: 'demo-model')
      request_headers = client.send(:adapter).send(:request_headers).dup
      normalized_request_headers = request_headers.each_with_object({}) do |(key, value), acc|
        acc[key.to_s.downcase] = value
      end
      adapter_api_key = client.send(:adapter).send(:api_key)

      expect(adapter_api_key).to eq(provider_api_key) if provider_api_key

      provider_expected_headers.each do |key, value|
        expect(normalized_request_headers[key.to_s.downcase]).to eq(value)
      end

      response = client.chat(messages: messages)

      expect(captured_headers).not_to be_nil

      expect(response).to be_a(AiModels::Response)
      expect(response.content).to eq('Sidekiq is a background job processor.')
      expect(response.model).to eq('demo-model')
      expect(response.finish_reason).to eq('stop')
    end

    it 'returns an enumerator for streaming mode' do
      stream = AiModels.chat_stream(provider: provider_name, model: 'demo-model', messages: messages)
      expect(stream).to be_a(Enumerator)
    end
  end

  context 'with Groq' do
    let(:provider_name) { :groq }
    let(:provider_url) { 'https://api.groq.com/openai/v1' }
    let(:provider_api_key) { 'secret' }
    let(:provider_endpoint) { 'https://api.groq.com/openai/v1/chat/completions' }

    include_examples 'an openai-compatible provider'
  end

  context 'with LM Studio' do
    let(:provider_name) { :lm_studio }
    let(:provider_url) { 'http://localhost:1234/v1' }

    include_examples 'an openai-compatible provider'
  end

  context 'with LocalAI' do
    let(:provider_name) { :localai }
    let(:provider_url) { 'http://localhost:8080/v1' }

    include_examples 'an openai-compatible provider'
  end

  context 'with vLLM' do
    let(:provider_name) { :vllm }
    let(:provider_url) { 'http://localhost:8000/v1' }

    include_examples 'an openai-compatible provider'
  end

  context 'with OpenRouter' do
    let(:provider_name) { :openrouter }
    let(:provider_url) { 'https://openrouter.ai/api/v1' }
    let(:provider_api_key) { 'secret' }
    let(:provider_extra_config) { { http_referer: 'https://example.com', x_title: 'MyApp' } }
    let(:provider_expected_headers) { { 'HTTP-Referer' => 'https://example.com', 'X-Title' => 'MyApp' } }

    include_examples 'an openai-compatible provider'
  end
end
