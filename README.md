# ai_models

`ai_models` is a Rails-native abstraction layer for AI and LLM providers. It is designed like a framework component, not a thin HTTP wrapper, with a unified chat API, normalized responses, provider adapters, configurable middleware, streaming, and Rails integration.

## Features

- Unified public API with `AiModels.chat` and `AiModels.chat_stream`
- Provider abstraction for Ollama, DeepSeek, and OpenAI-compatible APIs
- Normalized `AiModels::Response` objects across providers
- Streaming via callback blocks or `Enumerator`
- Configurable middleware stack for retry and logging
- Rails Railtie and install generator
- Extensible architecture for future embeddings, tools, and agents

## Installation

Add the gem to your application:

```ruby
gem 'ai_models'
```

Then install dependencies:

```bash
bundle install
```

For Rails applications, generate the initializer:

```bash
rails g ai_models:install
```

## Configuration

```ruby
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

  config.before_request do |context|
    Rails.logger.debug("AI request provider=#{context.provider} model=#{context.model}")
  end

  config.after_response do |context|
    Rails.logger.info("AI completed in #{context.latency.round(3)}s")
  end

  config.on_error do |context|
    Rails.logger.error("AI error #{context.error.class}: #{context.error.message}")
  end

  config.on_retry do |context|
    Rails.logger.warn("Retry ##{context.retry_count} for #{context.provider}")
  end
end
```

## Usage

### Unified chat API

```ruby
response = AiModels.chat(
  provider: :ollama,
  model: 'deepseek-r1',
  messages: [
    { role: 'user', content: 'Explain Sidekiq' }
  ]
)

response.content
response.model
response.tokens
response.finish_reason
response.raw
```

### Streaming with a block

```ruby
AiModels.chat_stream(
  provider: :deepseek,
  model: 'deepseek-chat',
  messages: [
    { role: 'user', content: 'Explain Sidekiq' }
  ]
) do |chunk|
  puts chunk.content
end
```

### Streaming with an Enumerator

```ruby
stream = AiModels.chat_stream(
  provider: :ollama,
  model: 'llama3.1',
  messages: [
    { role: 'user', content: 'Stream this response' }
  ]
)

stream.each do |chunk|
  puts chunk.content
end
```

## Middleware

The middleware stack is configurable and follows a Faraday-style builder approach:

```ruby
AiModels.configure do |config|
  config.middleware do |middleware|
    middleware.use(AiModels::Middleware::Retry, max: 5)
    middleware.use(AiModels::Middleware::Logging)
  end
end
```

## Request lifecycle hooks

Global hooks allow you to instrument requests without coupling your app to a specific provider:

```ruby
AiModels.configure do |config|
  config.before_request do |context|
    context.provider
    context.model
    context.messages
    context.request_payload
  end

  config.after_response do |context|
    context.response
    context.latency
  end

  config.on_error do |context|
    context.error
    context.retry_count
  end

  config.on_retry do |context|
    context.error
    context.retry_count
  end
end
```

Each hook receives an `AiModels::Hooks::Context` with:

- `provider`
- `model`
- `messages`
- `request_payload`
- `response`
- `error`
- `retry_count`
- `latency`

Hook failures are swallowed and logged so instrumentation never breaks the request lifecycle.

## Provider architecture

- `AiModels::Providers::Base` defines the provider contract
- `AiModels::Providers::OpenAICompatible` is the reusable adapter for OpenAI-style APIs
- `AiModels::Providers::Ollama` uses Ollama's native chat endpoint and streaming format
- `AiModels::Providers::DeepSeek` extends the OpenAI-compatible adapter

All providers normalize their output into `AiModels::Response`.

## Error handling

The gem exposes a provider-agnostic error hierarchy:

- `AiModels::Errors::ConnectionError`
- `AiModels::Errors::AuthenticationError`
- `AiModels::Errors::RateLimitError`
- `AiModels::Errors::TimeoutError`
- `AiModels::Errors::ProviderError`

## Rails integration

The Railtie hooks into Rails logging and exposes an install generator:

```bash
rails g ai_models:install
```

This creates:

```text
config/initializers/ai_models.rb
```

## Testing

The test stack uses:

- RSpec
- WebMock

The architecture is intentionally ready to expand into embeddings, tool calling, and agent workflows without changing the public API.
