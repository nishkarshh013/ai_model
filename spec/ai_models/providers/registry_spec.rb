require 'spec_helper'

RSpec.describe AiModels::Providers::Registry do
  it 'registers the built-in providers' do
    providers = described_class.all

    expect(providers.keys).to include(
      :ollama,
      :deepseek,
      :openai,
      :groq,
      :lm_studio,
      :openrouter,
      :localai,
      :vllm
    )

    expect(described_class.fetch(:groq)).to eq(AiModels::Providers::Groq)
    expect(described_class.fetch(:lm_studio)).to eq(AiModels::Providers::LMStudio)
    expect(described_class.fetch(:openrouter)).to eq(AiModels::Providers::OpenRouter)
    expect(described_class.fetch(:localai)).to eq(AiModels::Providers::LocalAI)
    expect(described_class.fetch(:vllm)).to eq(AiModels::Providers::VLLM)
  end
end
