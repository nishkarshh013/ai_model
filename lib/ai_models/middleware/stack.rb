module AiModels
  module Middleware
    class Stack
      Entry = Struct.new(:middleware, :options, keyword_init: true)

      def self.default
        new.tap do |stack|
          stack.use(Retry)
          stack.use(Logging)
        end
      end

      def initialize
        @entries = []
      end

      def use(middleware, **options)
        @entries << Entry.new(middleware: middleware, options: options)
      end

      def apply(builder, **context)
        @entries.each do |entry|
          if entry.middleware.respond_to?(:apply)
            entry.middleware.apply(builder, entry.options, **context)
          else
            builder.use(entry.middleware, **entry.options)
          end
        end
      end

      def entries
        @entries.dup
      end
    end
  end
end
