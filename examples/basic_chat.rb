require 'ai_models'

response = AiModels.chat(
  provider: :ollama,
  model: 'llama3.2',
  messages: [
    {
      role: 'user',
      content: 'Explain Sidekiq simply'
    }
  ]
)

puts response.content