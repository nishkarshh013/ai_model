require 'spec_helper'

RSpec.describe AiModels::Providers::Ollama do
  let(:messages) do
    [{ role: 'user', content: 'Explain Sidekiq' }]
  end

  before do
    AiModels.configure do |config|
      config.providers = {
        ollama: {
          url: 'http://localhost:11434'
        }
      }
    end
  end

  it 'normalizes the native Ollama chat response' do
    stub_request(:post, 'http://localhost:11434/api/chat')
      .with(
        body: {
          model: 'deepseek-r1',
          messages: messages,
          stream: false
        }.deep_stringify_keys
      )
      .to_return(
        status: 200,
        body: Oj.dump(
          {
            'model' => 'deepseek-r1',
            'message' => {
              'role' => 'assistant',
              'content' => 'Sidekiq processes jobs asynchronously.'
            },
            'done' => true,
            'done_reason' => 'stop',
            'prompt_eval_count' => 14,
            'eval_count' => 7
          }
        )
      )

    response = AiModels.chat(
      provider: :ollama,
      model: 'deepseek-r1',
      messages: messages
    )

    expect(response.content).to eq('Sidekiq processes jobs asynchronously.')
    expect(response.model).to eq('deepseek-r1')
    expect(response.tokens).to eq(
      prompt_tokens: 14,
      completion_tokens: 7,
      total_tokens: 21
    )
    expect(response.finish_reason).to eq('stop')
  end
end
