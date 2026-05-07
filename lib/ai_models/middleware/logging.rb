module AiModels
  module Middleware
    class Logging < Faraday::Middleware
      def initialize(app, logger: nil)
        super(app)
        @logger = logger
      end

      def call(env)
        logger = @logger || AiModels.configuration.logger

        logger.info("[AiModels] #{env.method.to_s.upcase} #{env.url}") if logger

        @app.call(env).on_complete do |response_env|
          next unless logger

          logger.info("[AiModels] status=#{response_env.status}")
        end
      end

      class << self
        def apply(builder, options = {}, global_config: nil, **)
          builder.use(self, logger: options[:logger] || global_config&.logger)
        end
      end
    end
  end
end
