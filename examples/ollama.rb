require 'ai_models'

AiModels.configure do |config|
  config.providers = {
    ollama: {
      url: 'http://localhost:11434'
    }
  }
end

response = AiModels.chat(
  provider: :ollama,
  model: 'llama3.2',
  messages: [
    {
      role: 'user',
      content: 'What is Ruby on Rails?'
    }
  ]
)

puts response.content