module AiModels
  module Hooks
    class Registry
      EVENTS = %i[before_request after_response on_error on_retry].freeze

      def initialize
        @hooks = EVENTS.to_h { |event| [event, []] }
      end

      def register(event, &block)
        return hooks_for(event) unless block_given?

        hooks_for(event) << block
      end

      def run(event, context, logger:)
        hooks_for(event).each do |hook|
          hook.call(context)
        rescue StandardError => e
          logger&.error("[AiModels] #{event} hook failed: #{e.class}: #{e.message}")
        end
      end

      private

      attr_reader :hooks

      def hooks_for(event)
        hooks.fetch(event) do
          raise ArgumentError, "Unknown hook event: #{event}"
        end
      end
    end
  end
end
