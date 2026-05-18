require 'ai_models'

AiModels.configure do |config|
  config.providers = {
    lm_studio: {
      url: 'http://localhost:1234/v1',
      api_key: 'lm-studio'
    }
  }
end

response = AiModels.chat(
  provider: :lm_studio,
  model: 'tinyllama-1.1b-chat-v1.0',
  messages: [
    {
      role: 'user',
      content: 'Explain ActiveRecord associations'
    }
  ]
)

puts response.content