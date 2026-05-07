module AiModels
  class Client
    attr_reader :provider, :model, :options

    def initialize(provider: nil, model:, **options)
      @provider = (provider || AiModels.configuration.default_provider).to_sym
      @model = model
      @options = options
    end

    def chat(messages:, **opts)
      adapter.chat(messages: messages, model: model, stream: false, **opts)
    end

    def chat_stream(messages:, **opts, &block)
      adapter.chat(messages: messages, model: model, stream: true, **opts, &block)
    end

    private

    def adapter
      @adapter ||= begin
        provider_config = AiModels.configuration.provider_config(provider)
        provider_class = Providers::Registry.fetch(provider)

        provider_class.new(
          config: provider_config,
          global_config: AiModels.configuration
        )
      end
    end
  end
end
