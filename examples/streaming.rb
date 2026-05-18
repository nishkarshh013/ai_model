require 'ai_models'

AiModels.chat_stream(
  provider: :ollama,
  model: 'llama3.2',
  messages: [
    {
      role: 'user',
      content: 'Tell me a short story'
    }
  ]
) do |chunk|
  print chunk.content
end
