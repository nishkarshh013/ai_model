module AiModels
  class Configuration
    attr_accessor :default_provider, :timeout, :open_timeout, :max_retries, :retry_backoff, :logger

    def initialize
      @default_provider = :ollama
      @timeout = 60
      @open_timeout = 10
      @max_retries = 2
      @retry_backoff = ->(attempt) { 0.5 * (2**attempt.to_i) }
      @logger = default_logger
      @providers = {}
      @middleware = Middleware::Stack.default
      @hooks = Hooks::Registry.new
    end

    def providers
      @providers.deep_dup
    end

    def providers=(value)
      @providers = (value || {}).deep_symbolize_keys
    end

    def provider_config(name)
      @providers.fetch(name.to_sym, {}).deep_dup
    end

    def middleware
      @middleware ||= Middleware::Stack.default
      yield(@middleware) if block_given?
      @middleware
    end

    def hooks
      @hooks ||= Hooks::Registry.new
    end

    def reset_hooks!
      hooks.reset!
    end

    def before_request(&)
      hooks.register(:before_request, &)
    end

    def after_response(&)
      hooks.register(:after_response, &)
    end

    def on_error(&)
      hooks.register(:on_error, &)
    end

    def on_retry(&)
      hooks.register(:on_retry, &)
    end

    private

    def default_logger
      return ::Rails.logger if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger

      Logger.new($stdout)
    end
  end
end
