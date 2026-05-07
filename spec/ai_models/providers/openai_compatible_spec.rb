require 'spec_helper'

RSpec.describe AiModels::Providers::DeepSeek do
  let(:messages) do
    [{ role: 'user', content: 'Explain Sidekiq' }]
  end

  before do
    AiModels.configure do |config|
      config.providers = {
        deepseek: {
          api_key: 'secret',
          url: 'https://api.deepseek.com'
        }
      }
    end
  end

  it 'normalizes a non-streaming OpenAI-compatible response' do
    stub_request(:post, 'https://api.deepseek.com/v1/chat/completions')
      .with(
        body: {
          model: 'deepseek-chat',
          messages: messages
        }.deep_stringify_keys
      )
      .to_return(
        status: 200,
        body: Oj.dump(
          {
            'model' => 'deepseek-chat',
            'choices' => [
              {
                'message' => { 'content' => 'Sidekiq is a background job processor.' },
                'finish_reason' => 'stop'
              }
            ],
            'usage' => {
              'prompt_tokens' => 12,
              'completion_tokens' => 9,
              'total_tokens' => 21
            }
          }
        )
      )

    response = AiModels.chat(
      provider: :deepseek,
      model: 'deepseek-chat',
      messages: messages
    )

    expect(response.content).to eq('Sidekiq is a background job processor.')
    expect(response.model).to eq('deepseek-chat')
    expect(response.tokens).to eq(
      prompt_tokens: 12,
      completion_tokens: 9,
      total_tokens: 21
    )
    expect(response.finish_reason).to eq('stop')
  end

  it 'maps authentication failures into provider-agnostic errors' do
    stub_request(:post, 'https://api.deepseek.com/v1/chat/completions')
      .to_return(
        status: 401,
        body: Oj.dump(
          {
            'error' => {
              'message' => 'Invalid API key'
            }
          }
        )
      )

    expect do
      AiModels.chat(
        provider: :deepseek,
        model: 'deepseek-chat',
        messages: messages
      )
    end.to raise_error(AiModels::Errors::AuthenticationError, 'Invalid API key')
  end
end
