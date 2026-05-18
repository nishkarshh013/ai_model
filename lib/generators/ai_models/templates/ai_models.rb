AiModels.configure do |config|
  config.default_provider = :ollama
  config.timeout = 120
  config.open_timeout = 10
  config.max_retries = 3
  # config.log_level = :info
  # config.fallbacks = [
  #   :ollama,
  #   :deepseek,
  #   :groq
  # ]

  config.providers = {
    ollama: {
      url: 'http://localhost:11434'
    },
    deepseek: {
      api_key: ENV.fetch('DEEPSEEK_API_KEY', nil),
      url: 'https://api.deepseek.com'
    },
    lm_studio: {
      url: 'http://localhost:1234/v1',
      api_key: 'lm-studio',
      timeout: 300
    },
    groq: {
      api_key: ENV.fetch('GROQ_API_KEY', nil),
      url: 'https://api.groq.com/openai/v1'
    },
    openrouter: {
      api_key: ENV.fetch('OPENROUTER_API_KEY', nil),
      url: 'https://openrouter.ai/api/v1'
    }
  }

  config.middleware do |middleware|
    # middleware.use(AiModels::Middleware::Logging)
    # middleware.use(AiModels::Middleware::Retry, max: 3)
  end

  # config.before_request do |context|
  #   Rails.logger.debug("AI request id=#{context.request_id} provider=#{context.provider} attempt=#{context.attempt}")
  # end
  # config.after_response do |context|
  #   Rails.logger.info("AI request id=#{context.request_id} completed in #{context.latency.round(3)}s")
  # end
  # config.on_error do |context|
  #   Rails.logger.error(
  #     "AI request id=#{context.request_id} failed with #{context.error.class}: #{context.error.message}"
  #   )
  # end
  # config.on_retry do |context|
  #   Rails.logger.warn("AI request id=#{context.request_id} retry=#{context.retry_count} provider=#{context.provider}")
  # end
end
