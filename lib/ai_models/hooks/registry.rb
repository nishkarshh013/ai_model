module AiModels
  module Hooks
    class Registry
      EVENTS = %i[before_request after_response on_error on_retry].freeze

      def initialize
        @hooks = EVENTS.to_h { |event| [event, []] }
        @hook_keys = EVENTS.to_h { |event| [event, {}] }
        @mutex = Mutex.new
      end

      def register(event, &block)
        return hooks_for(event) unless block_given?

        @mutex.synchronize do
          key = hook_key(block)
          next if @hook_keys[event][key]

          hooks_for(event) << block
          @hook_keys[event][key] = true
        end
      end

      def reset!
        @mutex.synchronize do
          @hooks = EVENTS.to_h { |event| [event, []] }
          @hook_keys = EVENTS.to_h { |event| [event, {}] }
        end
      end

      def run(event, context, logger:)
        hooks_snapshot = @mutex.synchronize { hooks_for(event).dup }

        hooks_snapshot.each do |hook|
          hook.call(context)
        rescue StandardError => e
          logger&.error("[AiModels] #{event} hook failed: #{e.class}: #{e.message}")
        end
      end

      private

      attr_reader :hooks

      def hook_key(hook)
        location = hook.source_location
        location ? [:source_location, location] : [:object_id, hook.object_id]
      end

      def hooks_for(event)
        hooks.fetch(event) do
          raise ArgumentError, "Unknown hook event: #{event}"
        end
      end
    end
  end
end
