AiModels.configure do |config|
  config.default_provider = :ollama
  config.timeout = 120
  config.open_timeout = 10
  config.max_retries = 3

  config.providers = {
    ollama: {
      url: 'http://localhost:11434'
    },
    deepseek: {
      api_key: ENV['DEEPSEEK_API_KEY'],
      url: 'https://api.deepseek.com'
    }
  }

  config.middleware do |middleware|
    # middleware.use(AiModels::Middleware::Logging)
    # middleware.use(AiModels::Middleware::Retry, max: 3)
  end

  # config.before_request do |context|
  #   Rails.logger.debug("AI request provider=#{context.provider} model=#{context.model}")
  # end
  #
  # config.after_response do |context|
  #   Rails.logger.info("AI completed in #{context.latency.round(3)}s")
  # end
  #
  # config.on_error do |context|
  #   Rails.logger.error("AI error #{context.error.class}: #{context.error.message}")
  # end
  #
  # config.on_retry do |context|
  #   Rails.logger.warn("Retry ##{context.retry_count} for #{context.provider}")
  # end
end
